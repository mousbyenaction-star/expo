// Copyright 2019 650 Industries. All rights reserved.

import ExpoModulesCore
import EXUpdatesInterface

public final class E2ETestModule: Module, UpdatesStateChangeListener {
  private let methodQueue = DispatchQueue(label: "expo.modules.EXUpdatesQueue")
  private var updatesController: (any UpdatesE2ETestingInterface)?

  public func updatesStateDidChange(_ event: UpdatesStateEvent) {
    NSLog("E2ETestModule: updatesStateDidChange: \(event)")
  }

  public required init(appContext: AppContext) {
    super.init(appContext: appContext)
  }

  public func definition() -> ModuleDefinition {
    Name("ExpoUpdatesE2ETest")

    OnCreate {
      if let controller = UpdatesControllerRegistry.sharedInstance.controller as? UpdatesE2ETestingInterface {
        updatesController = controller
        controller.stateChangeListener = self
      }
    }

    OnDestroy {
      updatesController = nil
      if let controller = UpdatesControllerRegistry.sharedInstance.controller as? UpdatesE2ETestingInterface {
        controller.stateChangeListener = nil
      }
    }

    AsyncFunction("readInternalAssetsFolderAsync") { (promise: Promise) in
      updatesController?.getInternalDbAssetCountAsync(promise)
    }

    AsyncFunction("clearInternalAssetsFolderAsync") { (promise: Promise) in
      updatesController?.clearInternalDbAssetsAsync(promise)
    }
  }
}
