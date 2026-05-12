# AWS Security Checklist — T1580 Mitigation

This checklist operationalizes the controls proposed in the hardened architecture and aligns with NIST CSF 2.0, NIST SP 800-210, and ISO/IEC 27017.

## Identity and access (IAM)

- [ ] The root account is not used for operational tasks.
- [ ] The root account has MFA enabled.
- [ ] No policies attached to non-administrative identities contain `Action: "*"` and `Resource: "*"`.
- [ ] Every human identity with console access has MFA required.
- [ ] Programmatic access keys are rotated at least every 90 days.
- [ ] An explicit policy denies massive enumeration actions (`ec2:Describe*`, `s3:ListAllMyBuckets`, `iam:List*`, `iam:GetAccountAuthorizationDetails`) for non-privileged identities.
- [ ] Service roles follow least privilege.
- [ ] Unused users, roles, and keys are removed periodically.
- [ ] Permission Boundaries are applied to the most sensitive roles.

## Storage (Amazon S3)

- [ ] Block Public Access is enabled at the account level.
- [ ] All buckets have default encryption (SSE-S3 or SSE-KMS).
- [ ] Buckets storing relevant data have versioning enabled.
- [ ] Bucket policies use conditions (`aws:SourceIp`, `aws:SecureTransport`) where appropriate.
- [ ] S3 access logging is enabled to a dedicated bucket.
- [ ] No bucket is effectively public unless documented justification exists.

## Compute (Amazon EC2)

- [ ] Instances use IMDSv2 (`HttpTokens: required`).
- [ ] Security Groups only allow strictly necessary ports.
- [ ] No `0.0.0.0/0` rules on administrative ports (22, 3389).
- [ ] Administrative access uses AWS Systems Manager Session Manager rather than direct SSH.
- [ ] All instances are tagged minimally: `Project`, `Environment`, `Owner`.
- [ ] Automatic snapshots are configured for critical EBS volumes.

## Traceability (AWS CloudTrail)

- [ ] At least one multi-region trail is enabled.
- [ ] The trail captures management events and data events for sensitive S3 buckets.
- [ ] Log file integrity validation is enabled.
- [ ] Logs are stored in a dedicated S3 bucket with a policy preventing modification or deletion.
- [ ] Logs are forwarded to a CloudWatch Logs Log Group for analysis.

## Monitoring (AWS CloudWatch)

- [ ] A metric filter exists for `ec2:Describe*` calls with an associated alarm.
- [ ] A metric filter exists for `s3:List*` calls with an associated alarm.
- [ ] A metric filter exists for `iam:List*` and `iam:Get*` calls with an associated alarm.
- [ ] An alarm exists for massive failed (`AccessDenied`) calls from a single identity.
- [ ] Alarms notify a response channel (SNS, email, etc.).

## Resilience and recovery

- [ ] A backup strategy exists for EBS (automatic snapshots with retention).
- [ ] S3 versioning acts as protection against accidental deletion.
- [ ] The restoration procedure is documented.
- [ ] At least one successful restoration test has been performed.

## Framework compliance

- [ ] Applied controls are mapped to NIST CSF 2.0 (Identify, Protect, Detect, Respond, Recover).
- [ ] Applied controls are mapped to NIST SP 800-210 §4 (access control for IaaS).
- [ ] Applied controls are mapped to ISO/IEC 27017 (cloud-specific information security controls).

## Documentation

- [ ] Every implemented control has associated evidence in `evidence/`.
- [ ] The master log (`evidence/master-log.md`) is up to date.
- [ ] Screenshots are masked and uploaded to `evidence/captures/`.
