'use strict';

const { test } = require('node:test');
const assert = require('node:assert');

const { buildMessage, severityLabel } = require('../lambda/index');
const ec2Finding = require('../events/ec2-ssh-bruteforce.json');

test('severityLabel maps GuardDuty severities', () => {
  assert.strictEqual(severityLabel(8), 'HIGH');
  assert.strictEqual(severityLabel(5), 'MEDIUM');
  assert.strictEqual(severityLabel(2), 'LOW');
});

test('buildMessage includes the finding title and instance', () => {
  const message = buildMessage(ec2Finding.detail);

  assert.match(message.text, /SSH brute force/);
  assert.match(message.blocks[1].elements[0].text, /i-0a1b2c3d4e5f60789/);
});

for (const [file, expected] of [
  ['iam-anomalous-behavior.json', /Principal: claims-reports-uploader/],
  ['s3-anomalous-exfiltration.json', /Bucket: acme-claims-reports-prod/],
]) {
  test(`formats ${file} without EC2 fields`, () => {
    const finding = require(`../events/${file}`).detail;
    const message = buildMessage(finding);
    assert.match(message.blocks[1].elements[0].text, expected);
  });
}

test('unknown resources do not prevent an alert', () => {
  const message = buildMessage({ ...ec2Finding.detail, resource: {} });
  assert.match(message.blocks[1].elements[0].text, /Resource: unknown/);
});
