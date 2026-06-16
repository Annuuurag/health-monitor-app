const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, QueryCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.TABLE_NAME || 'HealthTelemetrySummaries';

exports.handler = async (event) => {
    try {
        const deviceId = event.queryStringParameters?.deviceId || 'esp32-user-1';
        
        // Fetch the last 20 readings for the device
        const params = {
            TableName: TABLE_NAME,
            KeyConditionExpression: 'deviceId = :did',
            ExpressionAttributeValues: {
                ':did': deviceId
            },
            ScanIndexForward: false, // Sort descending by timestamp
            Limit: 3000
        };

        const result = await dynamo.send(new QueryCommand(params));
        const items = result.Items || [];

        // Format for the Flutter App
        const responseData = items.map(item => ({
            deviceId:       item.deviceId,
            timestamp:      item.timestamp,
            heartRateBpm:   item.avgHeartRate  ?? 0,
            spo2Percent:    item.avgSpo2       ?? 0,
            bodyTempC:      item.avgTemp       ?? 0,
            readingsCount:  item.readingsCount ?? 1,
            signalQuality:  item.signalQuality ?? 0.95,
            activityLabel:  item.activityLabel ?? 'Resting',
            stepCount:      item.steps         != null ? Number(item.steps) : 0,
            fingerDetected: item.fingerDetected ?? false,
            source:         'AWS Backend',
            isAnomaly:      item.isAnomaly     ?? false,
            overallStatus:  item.overallStatus ?? 'Normal',
            summary:        item.summary       ?? 'Vitals look good.',
        }));

        const latest = responseData.length > 0 ? responseData[0] : null;
        
        let snapshot = null;
        if (latest) {
            snapshot = {
                deviceId: latest.deviceId,
                timestamp: latest.timestamp,
                heartRateBpm: latest.heartRateBpm,
                spo2Percent: latest.spo2Percent,
                bodyTempC: latest.bodyTempC,
                activityLabel: latest.activityLabel,
                stepCount: latest.stepCount,
                signalQuality: latest.signalQuality,
                overallStatus: latest.overallStatus,
                isAnomaly: latest.isAnomaly,
                summary: latest.summary
            };
        }

        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                snapshot: snapshot,
                samples: responseData
            })
        };

    } catch (error) {
        console.error("Error fetching data:", error);
        return {
            statusCode: 500,
            headers: {
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({ error: 'Internal Server Error' })
        };
    }
};
