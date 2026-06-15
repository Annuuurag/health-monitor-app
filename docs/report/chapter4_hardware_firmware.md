# Chapter 4: Hardware & Firmware Implementation

## 4.1 System Circuit Connections and Wiring Schematics
To build the health monitoring wearable, the sensor modules must be interfaced with the central processing microcontroller. This design utilizes a **classic ESP32** developer board. Because both the MPU6050 (Inertial Measurement Unit) and the MAX30102 (Photoplethysmography sensor) communicate using the **Inter-Integrated Circuit ($\text{I}^2\text{C}$)** serial protocol, they can share the same hardware bus lines.

### Shared Bus Topography
The system establishes a single $\text{I}^2\text{C}$ bus. The ESP32 acts as the bus master, initiating all read/write cycles. The MPU6050 and MAX30102 act as slaves. Address collision is avoided because the devices have unique fixed hardware addresses:
*   **MAX30102**: Address `0x57`
*   **MPU6050**: Address `0x68`

---

## 4.2 Microcontroller Pinout Allocations
In this design, we override the ESP32's default $\text{I}^2\text{C}$ pins to utilize **GPIO 21 (SDA)** and **GPIO 22 (SCL)**. This ensures clean board layouts and compatibility with classic ESP32 developer modules.

### Pinout Mapping Tables

#### Table 4.1: MAX30102 Pulse Oximeter to ESP32 Pin Mapping
| MAX30102 Pin | Pin Description | ESP32 GPIO Pin | Connection Type |
| :--- | :--- | :--- | :--- |
| **VCC** | Power Supply Input | **3.3V** | Power |
| **GND** | Ground Reference | **GND** | Ground |
| **SDA** | I2C Serial Data Line | **GPIO 21** | Digital Bidirectional |
| **SCL** | I2C Serial Clock Line | **GPIO 22** | Digital Input (driven by Master) |
| **INT** | Interrupt Output (Active Low) | *Not Connected* | Bypassed (using software polling) |

#### Table 4.2: MPU6050 IMU to ESP32 Pin Mapping
| MPU6050 Pin | Pin Description | ESP32 GPIO Pin | Connection Type |
| :--- | :--- | :--- | :--- |
| **VCC** | Power Supply Input | **3.3V** | Power |
| **GND** | Ground Reference | **GND** | Ground |
| **SDA** | I2C Serial Data Line | **GPIO 21** | Digital Bidirectional |
| **SCL** | I2C Serial Clock Line | **GPIO 22** | Digital Input (driven by Master) |
| **AD0** | I2C Address Select LSB | **GND** (selects `0x68`) | Ground (Hardware address pin) |

#### Table 4.3: Piezoelectric Buzzer to ESP32 Pin Mapping
| Buzzer Pin | Pin Description | ESP32 GPIO Pin | Connection Type |
| :--- | :--- | :--- | :--- |
| **Positive (+)** | Anode Trigger Line | **GPIO 25** | Digital Output (PWM capable) |
| **Negative (-)** | Cathode Return Line | **GND** | Ground |

---

## 4.3 ESP32 Firmware Implementation Details
The firmware is written in C++ using the Arduino framework. The complete logic is defined in [Combined_MPU_MAX_Dashboard.ino](file:///d:/Anurag/b.tech/final_year_project/health_monitor_app/ESP_code/Combined_MPU_MAX_Dashboard/Combined_MPU_MAX_Dashboard.ino). Below are the core modules and their implementation details.

### 4.3.1 Sensor Drivers & Bus Management
The I2C bus is initialized during `setup()` with a clock speed of 100 kHz. The sensors are configured by writing directly to their control registers.
*   **MPU6050 configuration**: The accelerometer full-scale range is set to $\pm 2g$ to achieve maximum resolution for step counting.
*   **MAX30102 configuration**: Setup parameters configure LED pulse amplitude, sample rates, and sample averaging.

```cpp
void setup() {
  Serial.begin(115200);
  delay(1000);

  // Initialize I2C Bus with custom pins
  Wire.begin(SDA_PIN, SCL_PIN);
  Wire.setClock(100000); // 100 kHz standard clock speed

  initMPU6050();
  initMAX30102();
  ...
}

void initMAX30102() {
  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("MAX30102 not found. Check wiring.");
    while (1);
  }
  // Setup: LED power = 60 (approx 12mA), sample avg = 4, mode = Multi-LED (2), 
  // sample rate = 400Hz, pulse width = 411us, ADC range = 4096
  particleSensor.setup(60, 4, 2, 400, 411, 4096);
  particleSensor.setPulseAmplitudeRed(0x1F); // Set red LED intensity
  particleSensor.setPulseAmplitudeIR(0x1F);  // Set IR LED intensity
  ...
}
```

### 4.3.2 Non-Blocking Data Polling & Buffer Logic
To ensure that high-frequency accelerometer processing (at 25 Hz) does not block or get interrupted by the slower PPG sensor reads, we use a non-blocking loop pattern. Instead of using `delay()`, the execution is controlled via timestamp checks against `millis()`.

Additionally, the inner loop of the MAX30102 polling checks if samples are available without pausing execution. While waiting for new PPG samples, it continues to call the accelerometer update function:

```cpp
// Collect 25 new samples for MAX30102 buffer update
fingerDetected = true;
for (byte i = 75; i < BUFFER_LENGTH; i++) {
  while (!particleSensor.available()) {
    particleSensor.check();
    // Keep sampling accelerometer at 25Hz while waiting for PPG sensor
    updateAccelerometerAndActivity(); 
    client.loop(); // Keep MQTT connection alive
  }

  long irValue  = particleSensor.getIR();
  long redValue = particleSensor.getRed();
  ...
}
```

### 4.3.3 Edge Step Count Implementation
The step counting algorithm measures the Euclidean magnitude of acceleration, pushes it to a circular buffer, and detects peaks that cross a dynamic threshold. A minimum lockout time (300 ms) prevents false triggers:

```cpp
// Step counting variables
float stepThreshold = 1.22;  // Peak threshold for a step in g
bool aboveThreshold = false;
unsigned long lastStepTime = 0;
const unsigned long minStepInterval = 300; // Hysteresis lockout in ms

void updateAccelerometerAndActivity() {
  static unsigned long lastMpuRead = 0;
  if (millis() - lastMpuRead >= 40) { // 25 Hz sampling rate (40ms interval)
    lastMpuRead = millis();
    readAndPrintMPU6050();

    // Calculate acceleration magnitude: Mag = sqrt(ax^2 + ay^2 + az^2)
    float mag = sqrt(g_ax * g_ax + g_ay * g_ay + g_az * g_az);

    // Store in circular magnitude buffer
    magBuffer[magIndex] = mag;
    magIndex = (magIndex + 1) % MAG_BUFFER_SIZE;
    if (magIndex == 0) {
      magBufferFull = true;
    }

    // Peak-detection step count logic with hysteresis
    if (mag > stepThreshold && !aboveThreshold) {
      if (millis() - lastStepTime > minStepInterval) {
        stepCount++;
        lastStepTime = millis();
        aboveThreshold = true;
      }
    } else if (mag < 1.08) {
      aboveThreshold = false;
    }
    
    // Update activity classification
    updateActivityState();
  }
}
```

### 4.3.4 Activity Recognition Heuristics Code
Activity recognition is processed on the edge by calculating the peak-to-peak amplitude range within the sliding window magnitude buffer. This range represents the intensity of the physical motion:

```cpp
float getMagnitudeRange() {
  float minM = 999.0;
  float maxM = -999.0;
  int count = magBufferFull ? MAG_BUFFER_SIZE : magIndex;
  if (count == 0) return 0.0;
  
  // Find min and max magnitude inside sliding window
  for (int i = 0; i < count; i++) {
    if (magBuffer[i] < minM) minM = magBuffer[i];
    if (magBuffer[i] > maxM) maxM = magBuffer[i];
  }
  return maxM - minM; // Fluctuation range
}

void updateActivityState() {
  float range = getMagnitudeRange();
  
  // Heuristic thresholds
  if (range < 0.18) {
    currentActivity = "Resting";
  } else if (range < 0.60) {
    currentActivity = "Walking";
  } else {
    currentActivity = "Jogging";
  }
}
```

### 4.3.5 Local HTTP Web Dashboard & JSON Endpoint
The ESP32 runs a local web server (on port 80). When a device on the same WiFi network accesses the ESP32's IP address, it serves an HTML page containing dashboard widgets. The webpage makes asynchronous AJAX calls to the `/data` endpoint every second to fetch the live metrics:

```cpp
WebServer server(80);

void setupWebEndpoints() {
  server.on("/",     handleRoot);
  server.on("/data", handleData);
  server.begin();
}

void handleRoot() {
  // Serves HTML string stored in PROGMEM (DASHBOARD_HTML)
  server.send(200, "text/html", DASHBOARD_HTML);
}

void handleData() {
  // Returns raw values and edge summaries in JSON format
  String json = "{";
  json += "\"ax\":"     + String(g_ax, 2) + ",";
  json += "\"ay\":"     + String(g_ay, 2) + ",";
  json += "\"az\":"     + String(g_az, 2) + ",";
  json += "\"gx\":"     + String(g_gx, 1) + ",";
  json += "\"gy\":"     + String(g_gy, 1) + ",";
  json += "\"gz\":"     + String(g_gz, 1) + ",";
  json += "\"temp\":"   + String(g_temp, 1) + ",";
  json += "\"beatAvg\":" + String(beatAvg) + ",";
  json += "\"spo2Avg\":" + String(spo2Avg) + ",";
  json += "\"finger\":"  + String(fingerDetected ? "true" : "false") + ",";
  json += "\"activityLabel\":\"" + currentActivity + "\",";
  json += "\"steps\":"   + String(stepCount);
  json += "}";
  server.send(200, "application/json", json);
}
```

### 4.3.6 Secure WiFi & SSL/TLS MQTT Handshake
To connect securely to the AWS IoT Core endpoint, we use the `WiFiClientSecure` library. It loads the Root CA certificate, the client certificate, and the private key, executing an SSL/TLS handshake on port 8883:

```cpp
WiFiClientSecure net = WiFiClientSecure();
PubSubClient client(net);

void connectAWS() {
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }
  
  if (client.connected()) return;
  
  client.disconnect();
  net.stop();
  
  // Load certificates
  net.setCACert(AWS_CERT_CA);
  net.setCertificate(AWS_CERT_CRT);
  net.setPrivateKey(AWS_CERT_PRIVATE);
  
  client.setServer(AWS_IOT_ENDPOINT, 8883); // Secure MQTT Port

  Serial.print("Connecting to AWS IoT Core...");
  String clientId = "ESP32-HealthMonitor-" + String(WiFi.macAddress());
  
  if (client.connect(clientId.c_str())) {
    Serial.println(" Connected!");
  } else {
    Serial.print(" failed, rc=");
    Serial.println(client.state());
  }
}
```
The telemetry is packed into a JSON document and published to the AWS topic `health/esp32-user-1/raw` every 5 seconds, transmitting edge parameters (steps, activity) continuously.
