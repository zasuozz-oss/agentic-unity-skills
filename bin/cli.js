#!/usr/bin/env node

const { execFileSync } = require("child_process");
const path = require("path");
const os = require("os");

const rootDir = path.resolve(__dirname, "..");

if (os.platform() === "win32") {
  const script = path.join(rootDir, "setup-project.ps1");
  execFileSync(
    "powershell",
    ["-ExecutionPolicy", "Bypass", "-File", script],
    { cwd: process.cwd(), stdio: "inherit" }
  );
} else {
  const script = path.join(rootDir, "setup-project.sh");
  execFileSync("bash", [script], {
    cwd: process.cwd(),
    stdio: "inherit",
  });
}
