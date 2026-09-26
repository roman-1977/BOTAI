# Apple App Review guardrails

Status: Required product and engineering constraint. Re-check current Apple rules before every submission.

## UGC and social

BOTAI public quizzes are user-generated content. Publication therefore requires objectionable-content filtering/moderation, in-app reporting, timely moderation handling, user blocking where users interact, and visible developer contact information. Do not design anonymous/random chat or an unmoderated public feed.

Since September 2026 App Store submissions must answer the social-media capability questions. A social feed/discovery experience with redistribution/amplification/interactions can trigger Apple's Social Media classification and a minimum 13+ rating. Keep friends/challenges distinct from a public social feed unless that tradeoff is intentional.

## Account and privacy

If account creation is supported, account deletion must be initiable in the app and must delete associated personal data unless retention is legally required. Shared UGC is included in Apple's deletion expectation; do not assume that making a quiz public automatically lets BOTAI retain it after account deletion. If retention/licensing is desired, it needs a deliberately designed legal/product model and must still satisfy Apple's current deletion rules.

If Sign in with Apple is used, revoke its tokens on account deletion. If third-party/social login is used for the primary account, implement an Apple-compliant equivalent login option unless an explicit guideline exception applies.

Publish an accessible privacy policy describing collection, use, sharing, retention/deletion and consent withdrawal. Request only permissions/data needed for the feature and provide alternatives where practical.

## Age and children

Do not claim Kids-category compliance by accident. If BOTAI intentionally targets children 11 and under, additional Kids rules, parental gates and stricter data practices apply. If social-media capability exists, age-rating/Declared Age Range implications must be designed before enabling it for minors.

## UX implementation gate

Before a feature enters implementation, record whether it affects UGC/moderation, social-media classification, age rating, privacy/data collection, account deletion, authentication, purchases/subscriptions, external links, notifications or protected-device permissions. App Review compliance is part of acceptance criteria, not a pre-release cleanup task.
