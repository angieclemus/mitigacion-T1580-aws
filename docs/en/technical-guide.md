# Technical Guide — T1580 Mitigation in AWS

> **Status**: draft. To be completed at the close of all four laboratory phases.

## 1. Executive summary

(One page. Synthesis of the problem, proposal, results, and deliverables. Written last.)

## 2. Context and problem

(Mirror the *Problem statement* and *Justification* of the thesis. Preserve consistency with the IEEE bibliography.)

## 3. Technique T1580 — Cloud Infrastructure Discovery

(Description derived from the *Theoretical framework*. Detail MITRE-documented procedures, typical enumerated resources, and why the technique is hard to detect without active observability.)

## 4. Laboratory architecture

### 4.1 Baseline (vulnerable) version
(See `architecture/01-baseline-vulnerable.md`.)

### 4.2 Hardened version
(See `architecture/02-hardened.md`.)

## 5. Implemented controls

| ID | Control | AWS Service | Reference framework |
| --- | --- | --- | --- |
| CTL-01 | Account-level Block Public Access | S3 | NIST CSF 2.0 PR.AC, ISO 27017 |
| CTL-02 | Default encryption | S3 | NIST CSF 2.0 PR.DS |
| ... | ... | ... | ... |

## 6. Attack simulation

### 6.1 Tool and approach
(Pacu from the local machine; see `attack-simulation/`.)

### 6.2 Execution against the baseline
(Summary from `evidence/01-attack-baseline-T1580.md`.)

### 6.3 Execution against the hardened architecture
(Summary from `evidence/03-attack-post-hardening.md`.)

## 7. Comparative results

(Comparative table of metrics: enumerated resources, % of successful calls, alarms generated, available traceability. This section is the heart of the work.)

## 8. Laboratory limitations

(Honestly document AWS Academy Learner Lab restrictions and how the methodological design was adapted.)

## 9. Conclusions and future work

(Synthesis of contributions, aligned with the four specific objectives. Future lines: extension to other MITRE techniques, SOAR integration, etc.)

## 10. Checklist

See `checklists/aws-security-checklist-en.md`.

## 11. References

(IEEE numbering, aligned with the main thesis.)
