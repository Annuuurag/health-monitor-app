#include <Wire.h>
#include "MAX30105.h"
#include "heartRate.h"
#include "spo2_algorithm.h"
#include <WiFi.h>
#include <WebServer.h>
#include <WiFiClientSecure.h>
#define MQTT_KEEPALIVE 60
#include <PubSubClient.h>

#include "secrets.h"


WebServer server(80);
WiFiClientSecure net = WiFiClientSecure();
PubSubClient client(net);

#define SDA_PIN 21
#define SCL_PIN 22

#include <time.h>

// ── NTP Time Synchronization Helper ───────────────────────
void syncNTP() {
  // Sync time with NTP server (GMT+5:30 offset)
  configTime(3600 * 5.5, 0, "pool.ntp.org", "time.nist.gov");
  Serial.print("Synchronizing time via NTP");
  time_t now = time(nullptr);
  int retry = 0;
  while (now < 1700000000 && retry < 30) {
    delay(500);
    Serial.print(".");
    now = time(nullptr);
    retry++;
  }
  if (now >= 1700000000) {
    Serial.println(" Done!");
    struct tm timeinfo;
    gmtime_r(&now, &timeinfo);
    Serial.print("Current UTC Time: ");
    Serial.println(asctime(&timeinfo));
  } else {
    Serial.println(" Failed (Timeout).");
  }
}

// ── AWS IoT Connection Helper ─────────────────────────────
void connectAWS() {
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }

  // Ensure any previous stale connection state or socket is fully cleaned up
  if (client.connected()) {
    return;
  }
  client.disconnect();
  net.stop();
  
  net.setCACert(AWS_CERT_CA); // Use the Root CA certificate now that time is synchronized
  net.setCertificate(AWS_CERT_CRT);
  net.setPrivateKey(AWS_CERT_PRIVATE);
  client.setServer(AWS_IOT_ENDPOINT, 8883);

  Serial.print("Connecting to AWS IoT Core...");
  String clientId = "ESP32-HealthMonitor-" + String(WiFi.macAddress());
  if (client.connect(clientId.c_str())) {
    Serial.println(" Connected!");
  } else {
    Serial.print(" failed, rc=");
    Serial.println(client.state());
  }
}


// ── MPU6050 ───────────────────────────────────────────────
const uint8_t MPU = 0x68;

// ── MPU6050 data globals ──────────────────────────────────
float g_ax, g_ay, g_az;
float g_gx, g_gy, g_gz;
float g_temp;

// ── Edge Activity Classifier & Step Counter Globals ──────
#define MAG_BUFFER_SIZE 50          // ~2 seconds at 25 Hz (smoother activity)
float magBuffer[MAG_BUFFER_SIZE];
int magIndex = 0;
bool magBufferFull = false;

String currentActivity = "Resting";
int stepCount = 0;

// ── Simplified Pedometer (Demo-Friendly) ─────────────────
// Uses a slow-adapting center point and raw magnitude crossings.
// The center auto-adapts to any sensor orientation/tilt.

float dynamicCenter = 1.0;            // Slow-moving average of magnitude
const float centerAlpha = 0.005;      // Slightly faster adaptation while resting
const float stepDelta   = 0.05;       // High sensitivity, since center is now locked during walking

bool  aboveThreshold = false;

// Timing guard
unsigned long lastStepTime = 0;
const unsigned long minStepInterval = 250;  // Allowed up to 4 steps/sec for jogging

// Smoothed activity range (EMA on the range itself)
float smoothedRange = 0.0;
const float rangeAlpha = 0.1;  // Smoothing for activity classification


// ── MAX30102 ──────────────────────────────────────────────
MAX30105 particleSensor;

const byte RATE_SIZE = 8;
byte rates[RATE_SIZE];
byte rateSpot = 0;
long lastBeat = 0;
float beatsPerMinute;
int beatAvg;

const byte SPO2_SIZE = 8;
byte spo2Readings[SPO2_SIZE];
byte spo2Spot = 0;
int spo2Avg;

#define BUFFER_LENGTH 100
uint32_t irBuffer[BUFFER_LENGTH];
uint32_t redBuffer[BUFFER_LENGTH];
int32_t spo2;
int8_t  validSPO2;
int32_t heartRate;
int8_t  validHeartRate;

unsigned long lastSpo2Calc = 0;
#define SPO2_INTERVAL 2000

bool fingerDetected = false;

// ─────────────────────────────────────────────────────────
// Web Dashboard HTML
// ─────────────────────────────────────────────────────────
const char DASHBOARD_HTML[] PROGMEM = R"rawliteral(
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>ESP32 Health Monitor</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Segoe UI', sans-serif;
      background: #0f0f1a;
      color: #e0e0e0;
      min-height: 100vh;
      padding: 20px;
    }
    h1 {
      text-align: center;
      color: #00d4ff;
      font-size: 1.6rem;
      margin-bottom: 6px;
      letter-spacing: 1px;
    }
    .subtitle {
      text-align: center;
      font-size: 0.8rem;
      color: #555;
      margin-bottom: 20px;
    }
    .grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 14px;
      max-width: 700px;
      margin: 0 auto;
    }
    .card {
      background: #1a1a2e;
      border-radius: 14px;
      padding: 18px;
      border: 1px solid #222244;
    }
    .card.full { grid-column: span 2; }
    .card-title {
      font-size: 0.7rem;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: #556;
      margin-bottom: 10px;
    }
    .big-value {
      font-size: 2.4rem;
      font-weight: 700;
      line-height: 1;
    }
    .unit {
      font-size: 0.9rem;
      color: #778;
      margin-left: 4px;
    }
    .bpm   { color: #ff5577; }
    .spo2  { color: #00d4ff; }
    .temp  { color: #ffaa44; }
    .accel { color: #88ff88; }
    .gyro  { color: #bb88ff; }

    .row3 {
      display: flex;
      justify-content: space-between;
      gap: 8px;
    }
    .mini {
      flex: 1;
      text-align: center;
    }
    .mini .label {
      font-size: 0.65rem;
      color: #556;
      margin-bottom: 4px;
    }
    .mini .val {
      font-size: 1.2rem;
      font-weight: 600;
    }

    .finger-badge {
      display: inline-block;
      padding: 4px 12px;
      border-radius: 20px;
      font-size: 0.75rem;
      font-weight: 600;
      margin-bottom: 12px;
    }
    .finger-on  { background: #0d3320; color: #44ff88; border: 1px solid #44ff88; }
    .finger-off { background: #3a1010; color: #ff4444; border: 1px solid #ff4444; }

    .status-dot {
      display: inline-block;
      width: 8px; height: 8px;
      border-radius: 50%;
      background: #44ff88;
      margin-right: 6px;
      animation: pulse 1.5s infinite;
    }
    @keyframes pulse {
      0%,100% { opacity: 1; }
      50%      { opacity: 0.3; }
    }
    .footer {
      text-align: center;
      margin-top: 18px;
      font-size: 0.7rem;
      color: #333;
    }

    @media (max-width: 480px) {
      .grid { grid-template-columns: 1fr; }
      .card.full { grid-column: span 1; }
    }
  </style>
</head>
<body>
  <h1>⚡ ESP32 Health Monitor</h1>
  <p class="subtitle"><span class="status-dot"></span>Live · updates every second</p>

  <div class="grid">

    <!-- Heart Rate -->
    <div class="card">
      <div class="card-title">❤️ Heart Rate</div>
      <div id="finger-badge" class="finger-badge finger-off">No Finger</div><br/>
      <span class="big-value bpm" id="bpm">--</span>
      <span class="unit">bpm</span>
    </div>

    <!-- SpO2 -->
    <div class="card">
      <div class="card-title">🩸 SpO2</div>
      <br/>
      <span class="big-value spo2" id="spo2">--</span>
      <span class="unit">%</span>
    </div>

    <!-- Temperature -->
    <div class="card">
      <div class="card-title">🌡️ Temperature (MPU6050)</div>
      <br/>
      <span class="big-value temp" id="temp">--</span>
      <span class="unit">°C</span>
    </div>

    <!-- Accelerometer -->
    <div class="card">
      <div class="card-title">📐 Accelerometer</div>
      <div class="row3">
        <div class="mini"><div class="label">X</div><div class="val accel" id="ax">--</div></div>
        <div class="mini"><div class="label">Y</div><div class="val accel" id="ay">--</div></div>
        <div class="mini"><div class="label">Z</div><div class="val accel" id="az">--</div></div>
      </div>
      <div style="text-align:center;font-size:0.65rem;color:#445;margin-top:6px;">g-force</div>
    </div>

    <!-- Gyroscope -->
    <div class="card full">
      <div class="card-title">🔄 Gyroscope</div>
      <div class="row3">
        <div class="mini"><div class="label">X</div><div class="val gyro" id="gx">--</div></div>
        <div class="mini"><div class="label">Y</div><div class="val gyro" id="gy">--</div></div>
        <div class="mini"><div class="label">Z</div><div class="val gyro" id="gz">--</div></div>
      </div>
      <div style="text-align:center;font-size:0.65rem;color:#445;margin-top:6px;">°/s</div>
    </div>

    <!-- Activity & Steps -->
    <div class="card full">
      <div class="card-title">🏃 Activity & Steps (Edge Classifier)</div>
      <div class="row3">
        <div class="mini">
          <div class="label">Activity Status</div>
          <div class="val" id="activity" style="color: #00d4ff; font-size: 1.8rem; font-weight: 700;">--</div>
        </div>
        <div class="mini">
          <div class="label">Steps Counted</div>
          <div class="val" id="steps" style="color: #88ff88; font-size: 1.8rem; font-weight: 700;">--</div>
        </div>
      </div>
    </div>

    <!-- Debug Panel -->
    <div class="card full" style="border: 1px solid #ff8800;">
      <div class="card-title" style="color: #ff8800;">🔧 Debug Telemetry</div>
      <div class="row3">
        <div class="mini">
          <div class="label">Magnitude</div>
          <div class="val" id="dbg_mag" style="color: #ffaa44;">--</div>
        </div>
        <div class="mini">
          <div class="label">Center</div>
          <div class="val" id="dbg_center" style="color: #ffaa44;">--</div>
        </div>
        <div class="mini">
          <div class="label">Smoothed Range</div>
          <div class="val" id="dbg_srange" style="color: #ffaa44;">--</div>
        </div>
      </div>
      <div style="margin-top:12px;">
        <textarea id="logBox" readonly style="width:100%;height:150px;background:#0a0a14;color:#88ff88;border:1px solid #333;border-radius:8px;padding:8px;font-family:monospace;font-size:0.7rem;resize:vertical;"></textarea>
        <div style="display:flex;gap:8px;margin-top:8px;">
          <button onclick="copyLog()" style="flex:1;padding:8px;background:#ff8800;color:#000;border:none;border-radius:8px;font-weight:700;cursor:pointer;">📋 Copy Log</button>
          <button onclick="clearLog()" style="flex:1;padding:8px;background:#333;color:#fff;border:none;border-radius:8px;font-weight:700;cursor:pointer;">🗑 Clear</button>
        </div>
      </div>
    </div>

  </div>

  <p class="footer">ESP32-C3 · MPU6050 + MAX30102</p>

  <script>
    let logLines = [];

    async function fetchData() {
      try {
        const res = await fetch('/data');
        const d   = await res.json();

        document.getElementById('bpm').textContent  = d.beatAvg  > 0 ? d.beatAvg  : '--';
        document.getElementById('spo2').textContent = d.spo2Avg  > 0 ? d.spo2Avg  : '--';
        document.getElementById('temp').textContent = d.temp;
        document.getElementById('ax').textContent   = d.ax;
        document.getElementById('ay').textContent   = d.ay;
        document.getElementById('az').textContent   = d.az;
        document.getElementById('gx').textContent   = d.gx;
        document.getElementById('gy').textContent   = d.gy;
        document.getElementById('gz').textContent   = d.gz;
        document.getElementById('activity').textContent = d.activityLabel;
        document.getElementById('steps').textContent    = d.steps;
        document.getElementById('dbg_mag').textContent   = d.dbg_mag;
        document.getElementById('dbg_center').textContent = d.dbg_center;
        document.getElementById('dbg_srange').textContent = d.dbg_srange;

        // Append to log
        const line = 'mag=' + d.dbg_mag + '  center=' + d.dbg_center + '  sRange=' + d.dbg_srange + '  act=' + d.activityLabel + '  steps=' + d.steps;
        logLines.push(line);
        if (logLines.length > 200) logLines.shift();
        const box = document.getElementById('logBox');
        box.value = logLines.join('\n');
        box.scrollTop = box.scrollHeight;

        const badge = document.getElementById('finger-badge');
        if (d.finger) {
          badge.textContent  = '✅ Finger Detected';
          badge.className    = 'finger-badge finger-on';
        } else {
          badge.textContent  = '❌ No Finger';
          badge.className    = 'finger-badge finger-off';
        }
      } catch(e) { console.log('fetch error', e); }
    }

    function copyLog() {
      const box = document.getElementById('logBox');
      box.select();
      try {
        document.execCommand('copy');
        alert('Log copied to clipboard!');
      } catch (err) {
        alert('Could not copy automatically. Please select the text and copy manually.');
      }
    }

    function clearLog() {
      logLines = [];
      document.getElementById('logBox').value = '';
    }

    fetchData();
    setInterval(fetchData, 1000);
  </script>
</body>
</html>
)rawliteral";

// ─────────────────────────────────────────────────────────
void handleRoot() {
  server.send(200, "text/html", DASHBOARD_HTML);
}

void handleData() {
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
  json += "\"steps\":"   + String(stepCount) + ",";
  json += "\"dbg_mag\":"   + String(sqrt(g_ax*g_ax + g_ay*g_ay + g_az*g_az), 3) + ",";
  json += "\"dbg_center\":" + String(dynamicCenter, 3) + ",";
  json += "\"dbg_srange\":" + String(smoothedRange, 3);
  json += "}";
  server.send(200, "application/json", json);
}

// ─────────────────────────────────────────────────────────
void initMPU6050() {
  Wire.beginTransmission(MPU);
  Wire.write(0x75);
  Wire.endTransmission(false);
  Wire.requestFrom(MPU, (size_t)1, true);
  uint8_t whoami = Wire.read();
  Serial.print("MPU6050 WHO_AM_I: 0x");
  Serial.println(whoami, HEX);

  Wire.beginTransmission(MPU);
  Wire.write(0x6B);
  Wire.write(0x80);
  Wire.endTransmission(true);
  delay(200);

  Wire.beginTransmission(MPU);
  Wire.write(0x6B);
  Wire.write(0x00);
  Wire.endTransmission(true);
  delay(200);

  Serial.println("MPU6050 Ready");
}

void initMAX30102() {
  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("MAX30102 not found. Check wiring.");
    while (1);
  }

  particleSensor.setup(60, 4, 2, 400, 411, 4096);
  particleSensor.setPulseAmplitudeRed(0x3F); // ~12.5mA (Double the default, half the max)
  particleSensor.setPulseAmplitudeIR(0x3F);

  for (byte i = 0; i < BUFFER_LENGTH; i++) {
    while (!particleSensor.available())
      particleSensor.check();
    redBuffer[i] = particleSensor.getRed();
    irBuffer[i]  = particleSensor.getIR();
    particleSensor.nextSample();
  }

  maxim_heart_rate_and_oxygen_saturation(
    irBuffer, BUFFER_LENGTH, redBuffer,
    &spo2, &validSPO2,
    &heartRate, &validHeartRate
  );

  Serial.println("MAX30102 Ready");
}

void readAndPrintMPU6050() {
  Wire.beginTransmission(MPU);
  Wire.write(0x3B);
  Wire.endTransmission(false);
  if (Wire.requestFrom(MPU, (size_t)14, true) == 14) {
    int16_t AcX = (Wire.read() << 8) | Wire.read();
    int16_t AcY = (Wire.read() << 8) | Wire.read();
    int16_t AcZ = (Wire.read() << 8) | Wire.read();
    int16_t Tmp = (Wire.read() << 8) | Wire.read();
    int16_t GyX = (Wire.read() << 8) | Wire.read();
    int16_t GyY = (Wire.read() << 8) | Wire.read();
    int16_t GyZ = (Wire.read() << 8) | Wire.read();

    g_ax   = AcX / 16384.0;
    g_ay   = AcY / 16384.0;
    g_az   = AcZ / 16384.0;
    g_gx   = GyX / 131.0;
    g_gy   = GyY / 131.0;
    g_gz   = GyZ / 131.0;
    g_temp = (Tmp / 340.0) + 36.53;
  }
}

float getMagnitudeRange() {
  float minM = 999.0;
  float maxM = -999.0;
  int count = magBufferFull ? MAG_BUFFER_SIZE : magIndex;
  if (count == 0) return 0.0;
  for (int i = 0; i < count; i++) {
    if (magBuffer[i] < minM) minM = magBuffer[i];
    if (magBuffer[i] > maxM) maxM = magBuffer[i];
  }
  return maxM - minM;
}

void updateAccelerometerAndActivity() {
  static unsigned long lastMpuRead = 0;
  if (millis() - lastMpuRead >= 40) { // 25 Hz sampling rate
    lastMpuRead = millis();
    readAndPrintMPU6050();

    // Calculate raw magnitude
    float rawMag = sqrt(g_ax * g_ax + g_ay * g_ay + g_az * g_az);

    // ── SANITY FILTER: Replace corrupted I2C reads ───────
    // If we receive a physically impossible value (like 0.25g or 4.0g) 
    // due to I2C noise, we DO NOT return (which would freeze the pedometer).
    // Instead, we replace it with the last known good reading.
    static float lastGoodMag = 1.0;
    if (rawMag < 0.5 || rawMag > 2.5) {
      rawMag = lastGoodMag;
    } else {
      lastGoodMag = rawMag;
    }

    // ── 3-SAMPLE MEDIAN FILTER ──
    // A 5-sample filter was too aggressive and erased actual fast footsteps!
    // A 3-sample filter deletes 1-sample I2C spikes but keeps real foot impacts.
    static float m[3] = {1.0, 1.0, 1.0};
    m[2] = m[1]; m[1] = m[0]; m[0] = rawMag;
    
    // Sort 3 items to find median
    float a = m[0], b = m[1], c = m[2];
    if (a > b) { float t=a; a=b; b=t; }
    if (b > c) { float t=b; b=c; c=t; }
    if (a > b) { float t=a; a=b; b=t; }
    float medianMag = b;

    // Apply a light smoothing filter to the cleaned median
    static float mag = 1.0;
    mag = 0.6 * medianMag + 0.4 * mag;

    // Store in circular buffer (used for activity classification)
    magBuffer[magIndex] = mag;
    magIndex = (magIndex + 1) % MAG_BUFFER_SIZE;
    if (magIndex == 0) {
      magBufferFull = true;
    }

    // ── Update dynamic center ONLY when resting ───────────
    // If we update this while walking, the average magnitude pulls the center upward, 
    // causing the algorithm to miss lighter footsteps.
    if (smoothedRange < 0.20) {
      dynamicCenter = centerAlpha * mag + (1.0 - centerAlpha) * dynamicCenter;
    }

    // ── Step detection (dynamic threshold crossing) ──────
    float upperThresh = dynamicCenter + stepDelta;
    float lowerThresh = dynamicCenter - stepDelta;

    if (!aboveThreshold && mag > upperThresh) {
      aboveThreshold = true;
    }
    if (aboveThreshold && mag < lowerThresh) {
      aboveThreshold = false;
      unsigned long now = millis();
      if (now - lastStepTime >= minStepInterval) {
        stepCount++;
        lastStepTime = now;
        Serial.printf("[STEP] count=%d  mag=%.3f  center=%.3f\n", stepCount, mag, dynamicCenter);
      }
    }

    // ── Activity classification (smoothed range) ─────────
    float range = getMagnitudeRange();
    smoothedRange = rangeAlpha * range + (1.0 - rangeAlpha) * smoothedRange;
    
    if (smoothedRange < 0.20) {
      currentActivity = "Resting";
    } else if (smoothedRange < 0.50) {
      currentActivity = "Walking";
    } else {
      currentActivity = "Jogging";
    }

    // Debug output every 500ms
    static unsigned long lastDebug = 0;
    if (millis() - lastDebug >= 500) {
      lastDebug = millis();
      Serial.printf("[DEBUG] mag=%.3f  center=%.3f  upper=%.3f  lower=%.3f  sRange=%.3f  activity=%s  steps=%d\n",
                    mag, dynamicCenter, upperThresh, lowerThresh, smoothedRange, currentActivity.c_str(), stepCount);
    }
  }
}


// ─────────────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  delay(1000);

  Wire.begin(SDA_PIN, SCL_PIN);
  Wire.setClock(100000);

  // Initialize MAX30102 FIRST because its library calls Wire.begin() 
  // internally, which resets the I2C bus state.
  initMAX30102();
  
  // FORCE the I2C bus back to our chosen pins
  Wire.begin(SDA_PIN, SCL_PIN);
  Wire.setClock(400000); // 400kHz Fast Mode

  // Initialize MPU6050 SECOND so its wake-up command isn't erased
  initMPU6050();

  // ── Connect to WiFi ───────────────────────────────────
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi Connected!");
  Serial.print("Open dashboard at: http://");
  Serial.println(WiFi.localIP());

  server.on("/",     handleRoot);
  server.on("/data", handleData);
  server.begin();

  // ── Sync NTP Time ─────────────────────────────────────
  syncNTP();

  // ── Connect to AWS IoT Core (Initial attempts) ────────
  int attempts = 0;
  while (!client.connected() && attempts < 3) {
    connectAWS();
    if (!client.connected()) {
      delay(2000);
    }
    attempts++;
  }

  Serial.println("Both sensors ready!");
  Serial.println("Place finger on MAX30102 for heart rate and SpO2.");
  Serial.println("=========================================");
}

void loop() {
  server.handleClient();  // handle web requests

  // ── AWS Connection Check ──────────────────────────────
  static unsigned long lastAwsReconnect = 0;
  if (!client.connected() && WiFi.status() == WL_CONNECTED) {
    if (millis() - lastAwsReconnect >= 10000) {
      lastAwsReconnect = millis();
      connectAWS();
    }
  }
  client.loop();

  updateAccelerometerAndActivity(); // Ensure accelerometer runs continuously

  // ── Shift buffer ──────────────────────────────────────
  for (byte i = 25; i < BUFFER_LENGTH; i++) {
    redBuffer[i - 25] = redBuffer[i];
    irBuffer[i - 25]  = irBuffer[i];
  }

  // ── Collect 25 new samples ────────────────────────────
  fingerDetected = true;
  for (byte i = 75; i < BUFFER_LENGTH; i++) {
    while (!particleSensor.available()) {
      particleSensor.check();
      updateAccelerometerAndActivity(); // Keep sampling accelerometer at 25Hz while waiting
      client.loop(); // Keep MQTT connection alive and respond to pings
    }

    long irValue  = particleSensor.getIR();
    long redValue = particleSensor.getRed();

    // ── Finger check ─────────────────────────────────────
    if (irValue < 50000) {
      fingerDetected = false;

      rateSpot = 0;
      spo2Spot = 0;
      beatAvg  = 0;
      spo2Avg  = 0;
      memset(rates, 0, sizeof(rates));
      memset(spo2Readings, 0, sizeof(spo2Readings));
      break;
    }

    if (checkForBeat(irValue)) {
      long delta = millis() - lastBeat;
      lastBeat = millis();
      beatsPerMinute = 60.0 / (delta / 1000.0);

      if (beatsPerMinute > 40 && beatsPerMinute < 180) {
        rates[rateSpot++] = (byte)beatsPerMinute;
        rateSpot %= RATE_SIZE;

        beatAvg = 0;
        for (byte x = 0; x < RATE_SIZE; x++)
          beatAvg += rates[x];
        beatAvg /= RATE_SIZE;
      }
    }

    redBuffer[i] = redValue;
    irBuffer[i]  = irValue;
    particleSensor.nextSample();
  }

  // ── Recalculate SpO2 every 2 seconds (only with finger)
  if (fingerDetected && millis() - lastSpo2Calc >= SPO2_INTERVAL) {
    lastSpo2Calc = millis();

    maxim_heart_rate_and_oxygen_saturation(
      irBuffer, BUFFER_LENGTH, redBuffer,
      &spo2, &validSPO2,
      &heartRate, &validHeartRate
    );

    if (validSPO2 && spo2 >= 85 && spo2 <= 100) {
      spo2Readings[spo2Spot++] = (byte)spo2;
      spo2Spot %= SPO2_SIZE;

      spo2Avg = 0;
      for (byte x = 0; x < SPO2_SIZE; x++)
        spo2Avg += spo2Readings[x];
      spo2Avg /= SPO2_SIZE;
    }
  }

  // Ensure accelerometer updates at loop end
  updateAccelerometerAndActivity();

  // ── Publish telemetry to AWS IoT every 1.5 seconds ──────
  static unsigned long lastAwsPublish = 0;
  if (client.connected() && (millis() - lastAwsPublish >= 1500)) {
    lastAwsPublish = millis();
    
    String payload = "{";
    payload += "\"deviceId\":\"esp32-user-1\",";
    payload += "\"hr\":" + String(fingerDetected ? beatAvg : 0) + ",";
    payload += "\"spo2\":" + String(fingerDetected ? spo2Avg : 0) + ",";
    payload += "\"temp\":" + String(g_temp, 1) + ",";
    payload += "\"ax\":" + String(g_ax, 2) + ",";
    payload += "\"ay\":" + String(g_ay, 2) + ",";
    payload += "\"az\":" + String(g_az, 2) + ",";
    payload += "\"gx\":" + String(g_gx, 1) + ",";
    payload += "\"gy\":" + String(g_gy, 1) + ",";
    payload += "\"gz\":" + String(g_gz, 1) + ",";
    payload += "\"activityLabel\":\"" + currentActivity + "\",";
    payload += "\"steps\":" + String(stepCount) + ",";
    payload += "\"finger\":" + String(fingerDetected ? "true" : "false");
    payload += "}";
    
    Serial.print("Publishing to AWS IoT: ");
    Serial.println(payload);
    
    if (client.publish(AWS_IOT_TOPIC, payload.c_str())) {
      Serial.println("Publish Succeeded!");
    } else {
      Serial.println("Publish Failed.");
    }
  }
}

