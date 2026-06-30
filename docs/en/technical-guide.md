# Technical Guide — T1580 Mitigation in AWS

> **Status**: complete. Written at the close of all four laboratory phases (EXP-00 through EXP-03, CTL-01 through CTL-08).

## 1. Executive summary

The MITRE ATT&CK technique **T1580 — Cloud Infrastructure Discovery** describes the reconnaissance an adversary performs over a cloud account's resources (compute instances, storage buckets, IAM identities) once valid credentials have been obtained. This reconnaissance is typically the first step toward more severe objectives: lateral movement, data exfiltration, or deployment of unauthorized resources.

This work built and empirically evaluated, under the **Design Science Research** paradigm (Hevner et al.) [32], a verifiable artifact: a hardened IaaS architecture on AWS, accompanied by eight mitigation controls (CTL-01 through CTL-08) distributed across the identity, storage, and observability layers. The artifact's effectiveness was validated by executing the **same attack** — reproduced with the Pacu tool — against a deliberately vulnerable baseline architecture (EXP-01) and against the hardened architecture (EXP-03), using the same AWS Academy Learner Lab operating identity in both cases.

**Main result**: the **detection and observability** controls (multi-region CloudTrail, CloudWatch alarms) were fully effective — the same attack that left no trace against the baseline architecture (0 logs, 0 alarms) produced, against the hardened architecture, a complete forensic record and **six alarm activations** over approximately two hours of execution. However, the **prevention** controls aimed at restricting enumeration itself (Block Public Access, least-privilege IAM policy) **did not reduce the discovery surface**, because the validated threat model — compromised legitimate credentials — already carries broad permissions that no public-access control restricts, and the designed least-privilege policy (CTL-04) could not be attached to the operational role due to an administrative restriction inherent to the academic environment (`iam:AttachRolePolicy` denied).

This finding — an architecture that **detects** but does not always **prevent** — constitutes the central empirical contribution of this work: it provides evidence that, against T1580 executed with compromised credentials, the control with the greatest potential impact (IAM least privilege) is also the most sensitive to operational restrictions of the environment in which it is deployed, while observability controls are robust and reproducible even under such restrictions.

## 2. Context and problem

The adoption of cloud infrastructure has transformed organizations' operating models, proportionally increasing their attack surface. Amazon Web Services holds approximately 50% of the IaaS services market [1] and operates under a shared responsibility model: the provider secures the underlying infrastructure, while the secure configuration of the services consumed is the customer's responsibility [16]. This distinction, clear in theory, is in practice the leading source of exploitable vulnerabilities.

The magnitude of the problem is empirically documented. Breaches occurring in public clouds cost an average of USD 5.17 million per incident — the most expensive breach type recorded — and 40% of all breaches involve data distributed across multiple environments [2]. Valid account abuse was the initial access vector in 35% of cloud intrusions during 2024, a year in which such intrusions grew 26% [3]. The average breakout time (the interval between initial access and lateral movement) dropped to 48 minutes in 2024, with the fastest recorded case at 51 seconds [3] — a window that demands controls validated in advance, not designed in response to an active incident.

In this context, T1580 describes how an adversary, after compromising initial access, systematically enumerates instances, S3 buckets, and IAM policies through legitimate calls to AWS APIs [4]. Its danger lies in the fact that these calls are **indistinguishable, at the API level, from the normal behavior of authorized users** in the absence of active auditing — a condition aggravated by documented structural factors: 99% of cloud identities hold excessive permissions and 61% of AWS root accounts lack MFA [5], while CloudTrail misconfiguration shows a 100% error rate in sector audits [6]. Misconfiguration and inadequate change control are, in fact, the leading documented threat in cloud environments during 2024, surpassing even zero-day attacks [7].

The problem addressed by this work is twofold: (1) determine which IAM and observability controls effectively mitigate T1580 in an AWS IaaS architecture, and (2) generate reproducible empirical evidence of their effectiveness — overcoming the main limitation of purely documentary studies: the inability to verify whether proposed controls actually work in practice.

## 3. Technique T1580 — Cloud Infrastructure Discovery

MITRE ATT&CK (*Adversarial Tactics, Techniques, and Common Knowledge*) is a knowledge base of adversarial tactics and techniques built from observations of real-world attacks [8]. T1580 sits under the **Discovery** tactic (TA0007) and describes how an adversary, holding compromised credentials, identifies infrastructure resources in an IaaS environment — compute instances, snapshots, buckets, and databases — using APIs, the CLI, and third-party tools such as Pacu [4]. MITRE's Center for Threat-Informed Defense systematized the mapping of these techniques for IaaS environments in the *Defending IaaS with ATT&CK* project [9].

Documented procedures typically include:

- **Compute enumeration**: listing instances, images (AMIs), volumes, snapshots, security groups, and network configuration (VPCs, subnets, route tables) — calls such as `DescribeInstances` or `DescribeSnapshots` reveal the full topology of the compromised infrastructure [4].
- **Storage enumeration**: listing buckets via `ListBuckets`, their associated access policies, and, in cases of weak configuration, directly reading their contents [24].
- **Identity enumeration**: listing users, roles, groups, and IAM policies, including attempts to confirm effective permissions (`iam:SimulatePrincipalPolicy`, `GetAccountAuthorizationDetails`) [22].
- **Detection-service enumeration**: checking whether active observability mechanisms exist (CloudTrail, GuardDuty, Config, CloudWatch) before proceeding with more aggressive actions — a sophisticated adversary prioritizes operating in the absence of detection.

The strategic value of T1580 for the attacker lies in the fact that information gathered in this reconnaissance phase guides subsequent actions: selecting resources for privilege escalation, identifying data to exfiltrate, and defining lateral-movement paths. From a defensive standpoint, this makes T1580 a critical interruption point: if IAM controls restrict what a compromised credential can see, and observability mechanisms detect unusual API call patterns, the attack chain can be interrupted before the adversary completes its reconnaissance.

The difficulty of detecting T1580 lies in the fact that, except for the observability services mentioned above, **there is no "attack" signal distinguishable from a routine administrative query**. Mitigation, therefore, cannot rely solely on blocking these calls (which would break legitimate administrative operations) but on a combination of:

1. **Principle of least privilege** [19]: every identity should operate with the minimum set of permissions necessary for its function, avoiding excesses exploitable in case of compromise. This principle is particularly critical in IaaS environments, where the proliferation of identities, roles, and policies widens the attack surface [25].
2. **Reducing the public exposure** of storage resources through bucket policies, ACLs, and Block Public Access [24], so that successful enumeration does not automatically translate into unauthorized access.
3. **Active observability** through AWS CloudTrail, which logs every API call together with the requester's identity, timestamp, source IP, and request parameters [21], complemented by AWS CloudWatch to generate alarms on anomalous call volumes.

This laboratory designed and validated controls across all three dimensions.

## 4. Laboratory architecture

### 4.1 Baseline (vulnerable) version

Reference architecture reproducing structural exposure conditions documented in the literature: an EC2 instance with no network restrictions relevant to the experiment's scope, S3 buckets without Block Public Access or default encryption, absence of a dedicated CloudTrail trail, and no CloudWatch alarms configured. Full detail in `architecture/01-baseline-vulnerable.md`.

### 4.2 Hardened version

Target architecture, aligned with NIST SP 800-210, ISO/IEC 27017, and the security pillar of the AWS Well-Architected Framework, incorporating eight controls (CTL-01 through CTL-08) across the storage, identity, and observability layers. The full design — including controls that could not be validated due to academic-environment restrictions (MFA, IAM policy attachment) — is documented in `architecture/02-hardened.md`. Section 8 of this guide details the gap between the design and what was actually validated.

## 5. Implemented controls

| ID | Control | Category | Reference framework | Status |
| --- | --- | --- | --- | --- |
| CTL-01 | Account-level Block Public Access in S3 | S3 | NIST CSF 2.0 PR.AC [30]; ISO/IEC 27017 CLD.9.5 [29] | ☑ Applied and verified |
| CTL-02 | Default SSE-S3 encryption (AES-256) | S3 | NIST CSF 2.0 PR.DS [30]; ISO/IEC 27017 CLD.10.1 [29] | ☑ Applied and verified |
| CTL-03 | S3 bucket versioning | S3 / Resilience | NIST CSF 2.0 RC.RP [30] | ☑ Applied and verified (MFA Delete: not applicable in the lab) |
| CTL-04 | Least-privilege IAM policy (`DenyT1580Enumeration`) | IAM | Principle of least privilege [19]; NIST CSF 2.0 PR.AC-4 [30]; NIST SP 800-210 §4 [17] | ⚠ Policy created and verified; could not be attached to the operational role (`iam:AttachRolePolicy` denied by the lab) |
| CTL-05 | Mandatory MFA | IAM | NIST SP 800-63 [23]; NIST CSF 2.0 PR.AC-7 [30] | ⚠ Not applicable — the lab denies creation of IAM users and virtual MFA devices |
| CTL-06 | Multi-region CloudTrail trail with log file integrity validation | CloudTrail / Observability | AWS CloudTrail [21]; NIST CSF 2.0 DE.AE [30]; ISO/IEC 27017 CLD.12.4 [29] | ☑ Applied and verified |
| CTL-07 | CloudWatch alarm on anomalous `Describe*`/`List*` calls | CloudWatch / Observability | NIST CSF 2.0 DE.CM [30]; NIST SP 800-210 [17] | ☑ Applied and verified — empirically triggered in EXP-03 |
| CTL-08 | EBS snapshots and S3 versioning as a backup strategy | Resilience | NIST CSF 2.0 RC.RP [30] | ☑ Applied and verified — S3 version restoration confirmed in EXP-03 |

Configuration detail, executed commands, and verification evidence for each control are in `evidence/02-controls-implementation.md`.

**Summary**: 6 of 8 controls were fully applied and verified. The two non-applicable/non-attachable controls (CTL-04, CTL-05) share a common root cause — administrative restrictions of the AWS Academy Learner Lab over identity management — and are discussed as a methodological limitation in Section 8.

## 6. Attack simulation

### 6.1 Tool and approach

The simulation used **Pacu** (Rhino Security Labs) [27], the AWS exploitation framework that is the reference tool cited in MITRE ATT&CK's official documentation for T1580 [4], run from the operator's local machine — not from an EC2 instance inside the account — to preserve the realism of the threat model (an external adversary with leaked credentials). The same set of five modules was executed, in the same order, against both architectures to guarantee comparability: `iam__enum_users_roles_policies_groups`, `iam__enum_permissions`, `ec2__enum`, `s3__download_bucket`, and `detection__enum_services`. Full operational detail in `attack-simulation/`.

### 6.2 Execution against the baseline (EXP-01)

Against the baseline architecture, Pacu successfully enumerated **23 roles, 7 policies, 1 EC2 instance (with its public IP exfiltrated), 2 S3 buckets, and downloaded 2 files** containing fictitious sensitive data, in approximately 25 minutes. The `detection__enum_services` module confirmed the total absence of active detection mechanisms (0 trails, 0 alarms, 0 GuardDuty detectors). None of these actions generated an alert or left a persistent record. Full detail in `evidence/01-attack-baseline-T1580.md`.

### 6.3 Execution against the hardened architecture (EXP-03)

Against the hardened architecture, using the identity identical to EXP-01, results were mixed:

- IAM and EC2 enumeration produced **results identical to the baseline** (23 roles, 1 instance, the same public IP exfiltrated): no applied control restricts these calls at the IAM level, because CTL-04 could not be attached to the role.
- S3 exfiltration **was not blocked by CTL-01** (Block Public Access): this control restricts public/anonymous access, not the access of an authenticated identity of the account itself with permissions already granted. A third enumerable bucket was also found — the CloudTrail log bucket created by CTL-06 — potentially exposing the forensic evidence to the same compromised identity.
- The detection module confirmed, after correcting an operational limitation of Pacu in this environment (see Section 8), **1 active CloudTrail trail and 1 configured alarm**, versus the 0/0 of the baseline.
- Direct cross-verification with the AWS CLI confirmed that the `T1580-EnumerationDetected` alarm transitioned to `ALARM` state **six times** during the attack session (~2h20m), with peaks of up to 46 `Describe*`/`List*` calls in a single 5-minute window, and that the trail maintained continuous log delivery throughout the test.
- An additional resilience test confirmed the successful restoration of a previous version of a manipulated S3 object, with exact content and `ETag` match.

Full detail, including methodological notes on lab incidents encountered during the test, in `evidence/03-attack-post-hardening.md`.

## 7. Comparative results

| Metric | Baseline (EXP-01) | Hardened (EXP-03) | Reading |
| --- | --- | --- | --- |
| EC2 instances enumerated | 1 | 1 | No change — CTL-04 not attached |
| S3 buckets enumerated | 2 | 3 (includes the log bucket) | Worsens — new asset exposed by CTL-06 without additional access control |
| Files exfiltrated from S3 | 2 | 2 (+ objects from the log bucket) | No improvement |
| IAM roles/policies enumerated | 23 / 7 | 23 / 8 | No functional change |
| Visible CloudTrail trails | 0 | 1 | Improvement — observability now exists |
| CloudWatch alarm activations | 0 | 6 (over ~2h20m) | Improvement — active, functional detection |
| Forensic traceability | None | Complete (multi-region trail, integrity validation) | Substantial improvement |
| Time to first alarm | N/A | Minutes from the start of enumeration | Improvement — near real-time detection |
| Resilience to data tampering | Not tested | S3 restoration verified (identical ETag) | Improvement — recovery capability confirmed |

**Aggregate reading**: the hardened architecture did not reduce the *enumeration surface* available to an attacker with legitimate account credentials, but it transformed a completely silent attack into one **detected within minutes and with complete forensic traceability**, and demonstrated **verified recovery capability** against data tampering. These three dimensions — prevention, detection, resilience — did not advance uniformly, and that asymmetry is itself a relevant result for the thesis's discussion chapter.

## 8. Laboratory limitations

The AWS Academy Learner Lab imposed administrative restrictions that shaped both the design and the interpretation of the results:

1. **Inability to create IAM users or virtual MFA devices** (`iam:CreateUser`, `iam:CreateVirtualMFADevice` denied). This prevented implementing CTL-05 (MFA) and forced the use of the `voclabs` role as a single identity, collapsing the "victim" and "attacker" roles that, in a real production environment, would be separate. Documented since EXP-00.
2. **Inability to attach managed policies to roles** (`iam:AttachRolePolicy` denied). This prevented CTL-04 — the least-privilege policy specifically designed to deny T1580 enumeration actions — from having any real effect, despite having been correctly created and verified as an artifact. This is the single highest-impact limitation on the EXP-03 results: without it, no applied control restricts IAM/EC2 enumeration at the permission level.
3. **Opt-in regions not enabled in the lab account**, which caused a `ConnectTimeoutError` when running `ec2__enum` without restricting the region, and a false negative in `detection__enum_services` (initially reporting 0/0) because the module aborts enumeration of an API after the first `ACCESS DENIED` in a region other than `us-east-1`, never reaching the region where the resources actually exist. Both incidents were resolved by scoping the session to `us-east-1` (`--regions us-east-1` and `set_regions us-east-1`, respectively) and are documented as reproducible methodological notes in `evidence/master-log.md`.
4. **Limited budget** (50 USD) and automatic stopping of EC2 instances on session close, which constrained the scope of the resilience validation to a low-cost S3 version-restoration test rather than a full EBS volume restoration from snapshot.

These limitations do not invalidate the results; on the contrary, they evidence a real tension between security control design and the administrative restrictions of the environments where controls are deployed — a methodologically relevant finding in itself, particularly for organizations operating under shared-account models or with centralized IAM governance outside their direct control.

## 9. Conclusions and future work

This work is applied in nature: it aims to solve a documented practical problem — the absence of experimentally validated controls for mitigating T1580 in AWS IaaS — through an experimental approach that reproduces controlled attack conditions and measures the response of the implemented controls [31]. The laboratory met the four specific objectives of the thesis: (SO1) the T1580 exposure vectors across EC2, S3, and IAM were characterized on a deliberately vulnerable baseline architecture; (SO2) a hardened architecture was designed and implemented with eight controls distributed across identity, storage, and resilience; (SO3) the effectiveness of those controls was empirically validated through a controlled attack reproduced identically against both architectures, including cross-verification with the AWS CLI and a restoration test; (SO4) this bilingual technical guide, detailed per-phase evidence, and a traceable master log were produced and published in a public repository.

The main contribution is empirical — not merely theoretical — evidence that **observability** controls (CloudTrail, CloudWatch) are robust and reproducible against T1580 even in environments with severe administrative restrictions, while **IAM-based prevention** controls critically depend on governance permissions (such as `iam:AttachRolePolicy`) that may not be available to whoever designs the architecture — separating the responsibility of "designing the correct control" from that of "having the authority to apply it."

**Future lines of work**:
- Repeat EXP-03 in an AWS account with full administrative control, to verify whether an attached CTL-04 effectively reduces the enumeration surface to the levels expected by design.
- Extend the laboratory to other techniques within MITRE ATT&CK's cloud-domain Discovery tactic (e.g., T1526 — Cloud Service Discovery).
- Integrate CloudWatch alarms with an automated response flow (SOAR), evaluating containment time in addition to detection time.
- Evaluate the same control set under a multi-account model with AWS Organizations and Service Control Policies, where least privilege is enforced at the organizational level and does not depend on the compromised role's own permissions.

## 10. Checklist

See `checklists/aws-security-checklist-en.md` for the full operational checklist, organized by domain (IAM, S3, EC2, CloudTrail, CloudWatch, resilience) and mapped to NIST CSF 2.0, NIST SP 800-210, and ISO/IEC 27017.

## 11. References

> Numbering identical to the consolidated bibliography of the thesis document (`TESIS ANGIE2.docx`), to preserve citation consistency between both documents.

[1] SentinelOne, "Top 10 AWS Security Issues You Need to Know," 2025. [Online]. Available: https://tinyurl.com/aws-security-s1

[2] IBM, "Cost of a Data Breach Report 2024," IBM Security, Jul. 2024. [Online]. Available: https://tinyurl.com/ibm-breach-2024

[3] CrowdStrike, "2025 Global Threat Report," CrowdStrike, Feb. 2025. [Online]. Available: https://tinyurl.com/cs-threat-2025

[4] MITRE, "Cloud Infrastructure Discovery, Technique T1580," MITRE ATT&CK, 2024. [Online]. Available: https://attack.mitre.org/techniques/T1580/

[5] SecurityToday, "Cloud Misconfigurations: The 10 Most Dangerous Security Gaps in AWS and Azure," Feb. 2026. [Online]. Available: https://tinyurl.com/cloud-misconfig-2026

[6] Trend Micro, "The Most Common Cloud Misconfigurations That Could Lead to Security Breaches," 2021. [Online]. Available: https://tinyurl.com/trendmicro-misconfig

[7] RSA Conference, "Cloud Misconfigurations: Still the Biggest Threat in 2025?" Oct. 2025. [Online]. Available: https://tinyurl.com/rsa-cloudmisconfig

[8] B. Strom, A. Applebaum, D. Miller, K. Nickels, A. Pennington, and C. Thomas, "MITRE ATT&CK: Design and Philosophy," MITRE Corp., 2018. [Online]. Available: https://tinyurl.com/attck-design

[9] MITRE CTID, "Defending IaaS with ATT&CK," Center for Threat-Informed Defense, 2021. [Online]. Available: https://ctid.mitre.org/projects/attck-for-cloud/

[10] S. Roy et al., "MITRE ATT&CK Applications in Cybersecurity and The Way Forward," arXiv, 2023. [Online]. Available: https://tinyurl.com/attck-applications

[11] Z. Jadidi et al., "Threat Hunting Using MITRE ATT&CK Framework," in Proc. IEEE TrustCom, 2021.

[12] M. Munddt et al., "The Application of MITRE ATT&CK Framework in Mitigating Cyberattacks in the Public Sector," IACIS, 2024. [Online]. Available: https://tinyurl.com/attck-publicsector

[13] S. Achleitner et al., "Cyber Deception: Virtual Networks to Defend Insider Reconnaissance," in Proc. ACM CCS MIST Workshop, 2016.

[14] R. Guo et al., "A Practical Honeypot-Based Threat Intelligence Framework for Cloud Environments," arXiv, 2025. [Online]. Available: https://tinyurl.com/honeypot-cloud-2025

[15] P. Mell and T. Grance, "The NIST Definition of Cloud Computing," NIST SP 800-145, Sep. 2011. [Online]. Available: https://tinyurl.com/nist-800-145

[16] Amazon Web Services, "Shared Responsibility Model," 2023. [Online]. Available: https://tinyurl.com/aws-shared-resp

[17] V. Hu et al., "General Access Control Guidance for Cloud Systems," NIST SP 800-210, Jul. 2020. [Online]. Available: https://doi.org/10.6028/NIST.SP.800-210

[18] SANS Institute, "MITRE's Updated ATT&CK Framework: What Cloud Defenders Need to Know," 2023. [Online]. Available: https://tinyurl.com/sans-attck-cloud

[19] J. H. Saltzer and M. D. Schroeder, "The Protection of Information in Computer Systems," Proc. IEEE, vol. 63, no. 9, pp. 1278–1308, Sep. 1975.

[20] M. Kleppmann, *Designing Data-Intensive Applications*. Sebastopol, CA: O'Reilly Media, 2017.

[21] Amazon Web Services, "AWS CloudTrail Documentation," 2024. [Online]. Available: https://tinyurl.com/aws-cloudtrail-doc

[22] Amazon Web Services, "AWS Identity and Access Management," 2023. [Online]. Available: https://tinyurl.com/aws-iam-doc

[23] NIST, "Digital Identity Guidelines," NIST SP 800-63, 2017. [Online]. Available: https://tinyurl.com/nist-800-63

[24] Amazon Web Services, "Amazon S3 Documentation," 2024. [Online]. Available: https://tinyurl.com/aws-s3-doc

[25] NIST, "Glossary of Key Information Security Terms," NISTIR 7298 Rev. 3, 2019. [Online]. Available: https://tinyurl.com/nist-glossary

[26] Datadog, "State of Cloud Security 2024," 2024. [Online]. Available: https://tinyurl.com/datadog-cloudsec-2024

[27] Rhino Security Labs, "Pacu: The AWS Exploitation Framework," GitHub, 2019. [Online]. Available: https://github.com/RhinoSecurityLabs/pacu

[28] Amazon Web Services, "ISO/IEC 27001:2022 Compliance," 2024. [Online]. Available: https://tinyurl.com/aws-iso27001

[29] ISO/IEC, "ISO/IEC 27017:2015 – Code of Practice for Information Security Controls for Cloud Services," 2015. [Online]. Available: https://www.iso.org/standard/43757.html

[30] NIST, "Cybersecurity Framework 2.0," 2024. [Online]. Available: https://tinyurl.com/nist-csf-20

[31] R. Hernández-Sampieri, C. Fernández-Collado, and M. P. Baptista-Lucio, *Metodología de la Investigación*, 6th ed. Mexico City: McGraw-Hill, 2014.

[32] A. R. Hevner, S. T. March, J. Park, and S. Ram, "Design science in information systems research," *MIS Quarterly*, vol. 28, no. 1, pp. 75–105, Mar. 2004. [Online]. Available: https://doi.org/10.2307/25148625
