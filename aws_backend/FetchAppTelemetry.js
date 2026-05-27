const AWS = require('aws-sdk');
const dynamo = new AWS.DynamoDB.DocumentClient();

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
            Limit: 20
        };

        const result = await dynamo.query(params).promise();
        const items = result.Items || [];

        // Format for the Flutter App
        const responseData = items.map(item => ({
            deviceId: item.deviceId,
            timestamp: item.timestamp,
            heartRateBpm: item.avgHeartRate,
            spo2Percent: item.avgSpo2,
            bodyTempC: item.avgTemp,
            readingsCount: item.readingsCount || 1,
            signalQuality: item.signalQuality || 0.95,
            activityLabel: item.activityLabel || 'Resting',
            source: 'AWS Backend'
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
                signalQuality: latest.signalQuality,
                overallStatus: 'Normal',
                isAnomaly: false,
                summary: 'Your vitals are looking good.'
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
