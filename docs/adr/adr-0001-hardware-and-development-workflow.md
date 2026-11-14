# ADR-0001: Select Arduino UNO Q and Host-Based Development Workflow

- **Status:** Accepted
- **Date:** 2026-11-14
- **Decision makers:** Project team
- **Technical area:** Edge hardware and software development
- **Related issues:** None
- **Supersedes:** None
- **Superseded by:** None

## Context and Problem Statement

The VisioSense prototype needs an edge device for local processing and a repeatable way to deploy its code. The team selected the Arduino UNO Q. Source code is developed on host computers and maintained in GitHub.

Arduino App Lab runs in a container that cannot exchange files directly with the host repository. The host therefore needs to transfer the project to the board and invoke the UNO Q's app CLI. GitHub remains the source of truth, and deployments must use reviewed code from `master`.

## Decision Drivers

- Use the Arduino UNO Q as the prototype's edge device.
- Keep editable source in GitHub and develop it on host computers.
- Make deployments deliberate, reproducible, and traceable to a Git commit.
- Keep device-specific secrets out of GitHub and separate from deployed app files.

## Considered Options

1. **Host-based development with GitHub, ADB, and the board's app CLI:** Transfer the versioned app files from the host to the UNO Q over USB, then manage the app on the board.
2. **App Lab as the source interchange path:** Use App Lab to exchange or synchronize source between its container and the host repository.
3. **Device-based development:** Edit and maintain the primary source directly on the UNO Q.
4. **Different edge hardware and deployment workflow:** Select another device and its associated tooling.

## Decision Outcome

**Chosen option:** Arduino UNO Q with host-based development, GitHub source control, USB ADB transfer, and the UNO Q's `arduino-app-cli` for app lifecycle commands.

**Rationale:** GitHub provides the shared, reviewable source history. ADB transfers the host checkout to the UNO Q, where `arduino-app-cli` manages the app. App Lab's container is not used to exchange source with the host repository.

### Positive Consequences

- The team has a common hardware target and a single source of truth.
- Deployments can be tied to an exact commit on `master`.
- App source is separate from documentation in `apps/visiosense/`.
- Device secrets remain outside the versioned and replaced app directory.

### Negative Consequences and Trade-offs

- A designated maintainer must perform deployments manually over USB.
- The maintainer must keep the host checkout, device files, and commit record aligned.
- The application must read its device-only secrets file itself; the workflow does not rely on an App Lab secret-injection feature.

## Options Analysis

| Option | Benefits | Drawbacks | Notes |
| --- | --- | --- | --- |
| Host source, GitHub, ADB, board CLI | Reviewable source; explicit device deployment; commit traceability | Requires manual transfer and board commands | Chosen |
| App Lab container exchange | App Lab can run/manage apps | Does not provide the required host-directory interchange path | Not chosen for source transfer |
| Device-based source | Direct access to the board | Source would not be maintained primarily in GitHub | Not chosen |
| Different hardware/tooling | Could offer different capabilities | Changes the agreed hardware direction and toolchain | Not chosen |

## Implementation Notes

- [ ] Keep the deployable app in `apps/visiosense/`, with the App Lab app files at that directory's root.
- [ ] Protect `master` in GitHub: block direct pushes and require a pull request with at least one approval.
- [ ] Have the designated maintainer manually fetch `origin`, verify a clean local `master` that exactly matches `origin/master`, and record the commit hash before deployment.
- [ ] Over USB, stop the board app, replace `~/ArduinoApps/VisioSense` with the contents of `apps/visiosense/` using ADB, then start it with `arduino-app-cli app start user:VisioSense` through `adb shell`.
- [ ] Keep secrets in `~/visiosense.env` on the UNO Q, outside `~/ArduinoApps/VisioSense`. Restrict the file to the app's account and have the app read it directly.
- [ ] If a deployment must be rolled back, revert the change through a pull request and deploy the resulting `master` commit.
- [ ] Do not require an app startup or health check after deployment; record the deployed commit hash.

## Validation and Review

- **Success criteria:** The maintainer can verify that the device files came from the clean, current `origin/master` commit recorded for the deployment.
- **Review date or trigger:** Revisit if the hardware, App Lab container behavior, ADB transfer workflow, or app CLI lifecycle changes.

## References

- [VisioSense concept](../ideas.md#-idea-1-️-visiosense--ai-powered-local-visibility-monitoring)
- [Arduino UNO Q host-to-board workflow](https://docs.arduino.cc/pt/tutorials/uno-q/ai-coding-agents/)
- [Arduino UNO Q Debian guide](https://docs.arduino.cc/tutorials/uno-q/debian-guide/)
- [Arduino App specification](https://github.com/arduino/arduino-app-cli/blob/main/docs/app-specification.md)

## Change History

| Date | Change | Author |
| --- | --- | --- |
| 2026-11-14 | Initial proposal | Project team |
| 2026-11-14 | Accepted host-based GitHub-to-UNO Q deployment workflow | Project team |
