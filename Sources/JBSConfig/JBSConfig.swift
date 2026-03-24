// Copyright © 2026 Jean Silva
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program. If not, see https://www.gnu.org/licenses.

import ArgumentParser
import Foundation
import Subprocess
@preconcurrency import var TSCBasic.stdoutStream
import TSCUtility

/// This script is useful for when I get an unconfigured computer and whish to
/// customize it according to my default preferences and tools for the system
/// automatically.
@main
struct JBSConfig: AsyncParsableCommand {
  /// Total amount of steps of the configuration performed by this script.
  private static let stepCount = 3

  /// Named unit of work part of the configuration of this script. Represents
  /// an action which performs one or more related operations, and is associated
  /// to a function of an instance of a ``JBSConfig``.
  private struct Step {
    /// User-friendly title of this step. Consists of a concise description of
    /// what the `function` does, normally containing a verb in the infinitive
    /// form.
    let name: String

    /// Function for executing the actions of this step.
    private let function: () async throws -> Void

    /// Initializes a step of this script.
    ///
    /// - Parameters:
    ///   - name: User-friendly title of this step. Consists of a concise
    ///     description of what the `function` does, normally containing a verb
    ///     in the infinitive form.
    ///   - function: Function for executing the actions of this step.
    init(
      named name: String,
      calling function: @escaping () async throws -> Void
    ) {
      self.name = name
      self.function = function
    }

    /// Executes the actions of this step.
    func callAsFunction() async throws { try await function() }
  }

  mutating func run() async throws {
    let steps = [
      Step(named: "Changing wallpapers", calling: Self.changeWallpapers),
      Step(named: "Setting up Git", calling: Self.setUpGit),
      Step(named: "Installing Homebrew", calling: Self.installHomebrew)
    ]
    let progressAnimation = ProgressAnimation.percent(
      stream: stdoutStream,
      verbose: true,
      header: "Configuring",
      isColorized: true
    )
    for (position, step) in steps.enumerated() {
      progressAnimation.update(
        step: position,
        total: steps.count,
        text: step.name
      )
      try await step()
    }
  }

  // MARK: - Appearance

  /// As you're about to notice, I'm a pretty boring person when it comes to
  /// background images. This function sets the solid black color provided by
  /// macOS as the wallpaper of all desktops.
  ///
  /// - Throws: If the AppleScript by which the wallpapers are changed is not
  ///   found in the main bundle of the executable.
  static func changeWallpapers() async throws {
    guard
      let changerScriptURL = Bundle.main.url(
        forResource: "WallpaperChanger",
        withExtension: "applescript"
      )
    else { throw CocoaError(.fileNoSuchFile) }
    let _ = try await Subprocess.run(
      .name("osascript"),
      arguments: [changerScriptURL.path()],
      output: .discarded
    )
  }

  // MARK: - Tooling

  /// Identifies myself in Git (i.e., configures the user e-mail and name) and
  /// adds an alias with which I have been accostumed for ages: `git done`.
  static func setUpGit() async throws {
    try await withThrowingTaskGroup { taskGroup in
      taskGroup.addTask(name: "Identify myself") {
        let _ = try await Subprocess.run(
          .name("git"),
          arguments: ["config", "user.name", "Jean Silva"],
          output: .discarded
        )
        let _ = try await Subprocess.run(
          .name("git"),
          arguments: ["config", "user.email", "jeanbarrossilva@outlook.com"],
          output: .discarded
        )
      }
      taskGroup.addTask(name: "Add alias") {
        var alias = """
          git reset --hard
          git checkout main
          git pull origin main
          git reset --hard origin/main
          git branch --merged                 \
            | grep -v \\\\\\"\\\\\\\\*\\\\\\" \
            | grep -v main                    \
            | xargs -n 1 git branch -d
          """
        alias.replace(#/\n/#, with: " && ")
        alias.replace(#/ +/#, with: " ")
        let _ = try await Subprocess.run(
          .name("git"),
          arguments: ["config", "alias.done", "!\(alias)"],
          output: .discarded
        )
      }
      try await taskGroup.waitForAll()
    }
  }

  /// Fetches the installation script of Homebrew from its GitHub repository and
  /// executes it.
  ///
  /// - Throws: If the installation script cannot be fetched from the URL
  ///   specified in the Homebrew website (https://brew.sh). Normally, this
  ///   indicates that there is an issue with the internet connection of the
  ///   user; or, less probably, the file has been moved/removed.
  static func installHomebrew() async throws {
    guard
      let installationScript =
        try await Subprocess.run(
          .name("curl"),
          arguments: [
            "-fsSL",
            "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
          ],
          output: .string(limit: .max)
        )
        .standardOutput
    else { throw CocoaError(.fileReadNoSuchFile) }
    let _ = try await Subprocess.run(
      .name("bash"),
      arguments: ["-c", installationScript],
      output: .discarded
    )
  }
}
