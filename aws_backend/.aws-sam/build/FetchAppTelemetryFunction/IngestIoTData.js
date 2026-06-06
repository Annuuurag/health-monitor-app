const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.TABLE_NAME || 'HealthTelemetrySummaries';

exports.handler = async (event) => {
    // Expected event from AWS IoT Rule: 
    // { data: [... readings ...], deviceId: "esp32-user-1" }
    
    try {
        console.log("Received payload:", JSON.stringify(event));

        // If event is wrapped in a 'data' field, extract it
        let readings = [];
        if (Array.isArray(event)) {
            readings = event;
        } else if (event.data && Array.isArray(event.data)) {
            readings = event.data;
        } else if (event.data) {
            // It's a single reading instead of a batch
            readings = [event.data];
        } else {
            readings = [event]; // fallback
        }
        
        if (readings.length === 0) {
            return { statusCode: 200, body: 'No data to process' };
        }

        // Calculate averages over the variable frequency batch
        let totalHr = 0, totalSpo2 = 0, totalTemp = 0;
        let countHr = 0, countSpo2 = 0, countTemp = 0;

        readings.forEach(r => {
            if (r.hr != null) { totalHr += Number(r.hr); countHr++; }
            if (r.spo2 != null) { totalSpo2 += Number(r.spo2); countSpo2++; }
            if (r.temp != null) { totalTemp += Number(r.temp); countTemp++; }
        });

        const avgHr = countHr > 0 ? (totalHr / countHr) : 0;
        const avgSpo2 = countSpo2 > 0 ? (totalSpo2 / countSpo2) : 0;
        const avgTemp = countTemp > 0 ? (totalTemp / countTemp) : 0;

        const timestamp = new Date().toISOString();
        const deviceId = event.deviceId || 'esp32-user-1';

        const item = {
            deviceId: deviceId,
            timestamp: timestamp,
            avgHeartRate: parseFloat(avgHr.toFixed(2)),
            avgSpo2: parseFloat(avgSpo2.toFixed(2)),
            avgTemp: parseFloat(avgTemp.toFixed(2)),
            readingsCount: readings.length, // Log how many high-frequency samples were averaged
            signalQuality: 0.98,
            activityLabel: "Resting" // Placeholder for ML inference result
        };

        const params = {
            TableName: TABLE_NAME,
            Item: item
        };

        await dynamo.send(new PutCommand(params));
        console.log("Successfully saved summary to DynamoDB", item);

        return { statusCode: 200, body: 'Data processed and saved' };
    } catch (error) {
        console.error("Error processing IoT data:", error);
        throw error;
    }
};
