const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.TABLE_NAME || 'HealthTelemetrySummaries';

exports.handler = async (event) => {
    // Expected event from AWS IoT Rule:
    // Single reading: { deviceId, hr, spo2, temp, ax, ay, az, gx, gy, gz,
    //                   activityLabel, steps, finger }
    // Batched:        { data: [...readings], deviceId }

    try {
        console.log("Received payload:", JSON.stringify(event));

        let readings = [];
        if (Array.isArray(event)) {
            readings = event;
        } else if (event.data && Array.isArray(event.data)) {
            readings = event.data;
        } else if (event.data) {
            readings = [event.data];
        } else {
            readings = [event]; // single reading
        }

        if (readings.length === 0) {
            return { statusCode: 200, body: 'No data to process' };
        }

        // ── Averages (only include finger-present readings for HR / SpO2) ──
        let totalHr = 0, totalSpo2 = 0, totalTemp = 0;
        let countHr = 0,  countSpo2 = 0, countTemp = 0;
        let latestSteps = 0;
        let latestActivity = 'Resting';
        let fingerDetected = false;

        readings.forEach(r => {
            const fingerOn = r.finger === true || r.finger === 'true';
            if (fingerOn) fingerDetected = true;

            // Only average HR / SpO2 when a finger is present
            if (fingerOn) {
                if (r.hr  != null && Number(r.hr)   > 0)  { totalHr   += Number(r.hr);   countHr++;   }
                if (r.spo2 != null && Number(r.spo2) > 0)  { totalSpo2  += Number(r.spo2); countSpo2++; }
            }

            if (r.temp != null) { totalTemp += Number(r.temp); countTemp++; }

            // Use the latest step count & activity label from the batch
            if (r.steps != null)         latestSteps    = Number(r.steps);
            if (r.activityLabel != null) latestActivity = r.activityLabel;
        });

        const avgHr   = countHr   > 0 ? (totalHr   / countHr)   : 0;
        const avgSpo2 = countSpo2 > 0 ? (totalSpo2 / countSpo2) : 0;
        const avgTemp = countTemp > 0 ? (totalTemp / countTemp) : 0;

        // ── Derive simple status fields ────────────────────────────────────
        let overallStatus = 'Normal';
        let isAnomaly = false;
        const summaryParts = [];

        if (fingerDetected) {
            if (avgHr > 0 && (avgHr < 50 || avgHr > 120)) {
                overallStatus = 'Warning';
                isAnomaly = true;
                summaryParts.push(`Heart rate ${avgHr.toFixed(0)} bpm is outside normal range.`);
            }
            if (avgSpo2 > 0 && avgSpo2 < 95) {
                overallStatus = 'Warning';
                isAnomaly = true;
                summaryParts.push(`SpO2 ${avgSpo2.toFixed(0)}% is below 95%.`);
            }
        }
        if (avgTemp > 37.8) {
            overallStatus = 'Warning';
            isAnomaly = true;
            summaryParts.push(`Body temperature ${avgTemp.toFixed(1)} °C is elevated.`);
        }

        const summary = summaryParts.length > 0
            ? summaryParts.join(' ')
            : fingerDetected
                ? 'All vitals within normal range.'
                : 'No finger detected — HR & SpO2 unavailable.';

        const timestamp = new Date().toISOString();
        const deviceId  = event.deviceId || (readings[0] && readings[0].deviceId) || 'esp32-user-1';

        const item = {
            deviceId,
            timestamp,
            avgHeartRate:   parseFloat(avgHr.toFixed(2)),
            avgSpo2:        parseFloat(avgSpo2.toFixed(2)),
            avgTemp:        parseFloat(avgTemp.toFixed(2)),
            readingsCount:  readings.length,
            signalQuality:  0.98,
            activityLabel:  latestActivity,
            steps:          latestSteps,
            fingerDetected: fingerDetected,
            isAnomaly,
            overallStatus,
            summary,
        };

        await dynamo.send(new PutCommand({ TableName: TABLE_NAME, Item: item }));
        console.log("Saved to DynamoDB:", JSON.stringify(item));

        return { statusCode: 200, body: 'Data processed and saved' };

    } catch (error) {
        console.error("Error processing IoT data:", error);
        throw error;
    }
};
