# Project Blueprint

## Overview

This is a Flutter application. The primary goal is to develop and build the application for both Android and iOS platforms. The project utilizes GitHub Actions for continuous integration and automated builds.

## Features & Design

*(No specific features have been implemented yet.)*

## Current Goal: IPA Build for Testing

### Objective
The user wants to produce an `.ipa` file that can be installed on a physical iPhone for testing purposes.

### Progress & Challenges
1.  **Initial Setup:** A GitHub Actions workflow was created to build the Android APK and the iOS app.
2.  **Android Build:** The workflow successfully builds a release APK. An initial issue with the required Java version (11 vs. 17) was identified and resolved.
3.  **iOS Build & Code Signing:**
    *   The initial attempt to build an `.ipa` file failed with a "No valid code signing certificates were found" error.
    *   This is a standard requirement from Apple: all applications installed on physical devices must be digitally signed.
    *   The user suggested using `--export-method development`. It was explained that this method also requires a signature, just a different type (a Development Certificate instead of a Distribution Certificate).
    *   An alternative was implemented to build a version for the iOS simulator (`.app` file), which does not require code signing. However, this output **cannot** be installed on a physical iPhone.

### Blocker & Next Steps
The project is currently blocked from producing a testable `.ipa` file due to the lack of Apple Developer code signing certificates.

The following two options have been presented to the user:

*   **Option 1 (Recommended for `.ipa`):** Find a computer with macOS **one time** to generate the necessary code signing files (a `.p12` certificate and a `.mobileprovision` profile). These can then be added as secrets to the GitHub repository to enable automated, signed `.ipa` builds.
*   **Option 2 (Workaround for testing):** Change the goal to build a **web version** of the application. The web build can be automatically deployed and accessed via a URL in the browser on any device, including an iPhone, for testing UI and logic.

**Awaiting user decision on how to proceed.**
