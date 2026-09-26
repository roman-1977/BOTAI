# ADR-005: Local-first learning

Status: Accepted

## Decision

Core learning functionality must operate from local data.

The network backend synchronizes state but is not required for every learning interaction.

## Reasons

- fast interactions;
- offline study;
- resilience to backend/network failure;
- lower perceived latency;
- separation between learning engine and infrastructure.

## Consequence

A Sync Engine is a first-class architectural component rather than an afterthought.
