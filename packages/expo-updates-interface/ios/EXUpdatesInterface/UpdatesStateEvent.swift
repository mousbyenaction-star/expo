//  Copyright © 2021 650 Industries. All rights reserved.

/**
 All the possible types of events that can be sent to the machine. Each event
 will cause the machine to transition to a new state.
 */
public enum UpdatesStateEvent {
  case startStartup
  case endStartup
  case check
  case checkCompleteUnavailable
  case checkCompleteWithUpdate(manifest: [String: Any])
  case checkCompleteWithRollback(rollbackCommitTime: Date)
  case checkError(errorMessage: String)
  case download
  case downloadComplete
  case downloadCompleteWithUpdate(manifest: [String: Any])
  case downloadCompleteWithRollback
  case downloadError(errorMessage: String)
  case downloadProgress(progress: Double)
  case restart
}

