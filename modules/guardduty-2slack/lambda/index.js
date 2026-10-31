'use strict';

const https = require('node:https');

const MIN_SEVERITY = Number(process.env.MIN_SEVERITY || 4);

function severityLabel(severity) {
  if (severity >= 7) return 'HIGH';
  if (severity >= 4) return 'MEDIUM';
  return 'LOW';
}

function buildMessage(finding) {
  const resource = finding.resource || {};
  const details = [
    resource.instanceDetails?.instanceId && `Instance: ${resource.instanceDetails.instanceId}`,
    resource.accessKeyDetails?.userName && `Principal: ${resource.accessKeyDetails.userName}`,
    ...(resource.s3BucketDetails || []).map(bucket => `Bucket: ${bucket.name || bucket.arn}`),
  ].filter(Boolean).join(' | ') || `Resource: ${resource.resourceType || 'unknown'}`;

  return {
    text: `:rotating_light: GuardDuty ${severityLabel(finding.severity)}: ${finding.title}`,
    blocks: [
      {
        type: 'section',
        text: { type: 'mrkdwn', text: `*${finding.title}*\n${finding.description}` },
      },
      {
        type: 'context',
        elements: [
          {
            type: 'mrkdwn',
            text: `Type: ${finding.type} | Account: ${finding.accountId} | Region: ${finding.region} | ${details}`,
          },
        ],
      },
    ],
  };
}

function postToSlack(webhookUrl, payload) {
  return new Promise((resolve, reject) => {
    const req = https.request(
      webhookUrl,
      { method: 'POST', headers: { 'Content-Type': 'application/json' } },
      (res) => {
        res.resume();
        resolve();
      },
    );
    req.on('error', reject);
    req.write(JSON.stringify(payload));
    req.end();
  });
}

exports.handler = async (event) => {
  const finding = event.detail;

  if (finding.severity < MIN_SEVERITY) {
    return;
  }

  await postToSlack(process.env.SLACK_WEBHOOK_URL, buildMessage(finding));
};

exports.buildMessage = buildMessage;
exports.severityLabel = severityLabel;
