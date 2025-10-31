// Copyright 2015-present 650 Industries. All rights reserved.

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import React

#if os(tvOS) || os(macOS)
protocol PresentationControllerDelegate: AnyObject {
}
#else
protocol PresentationControllerDelegate: UISheetPresentationControllerDelegate {
}
#endif

#if os(macOS)
// macOS-specific implementation using NSWindow/NSView
class DevMenuWindow: NSWindow, PresentationControllerDelegate {
  private let manager: DevMenuManager
  private let devMenuViewController: NSViewController
  private var isPresenting = false
  private var isDismissing = false

  required init(manager: DevMenuManager) {
    self.manager = manager
    // DevMenuViewController is expected to be available as an NSViewController on macOS
    // (project should provide a macOS-ready implementation or a typealias that maps to NSViewController)
    self.devMenuViewController = DevMenuViewController(manager: manager)

    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
    super.init(contentRect: screenFrame,
               styleMask: [.borderless],
               backing: .buffered,
               defer: false)

    self.contentViewController = devMenuViewController
    self.isReleasedWhenClosed = false
    self.backgroundColor = NSColor(calibratedWhite: 0, alpha: 0.4)
    self.isOpaque = false
    self.level = .statusBar
    // Allow clicks to pass through if needed, but keep window key when opened
    self.ignoresMouseEvents = false
    // Start hidden; will be shown when needed
    self.orderOut(nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // Called when the window becomes key. Use this to trigger presentation similar to iOS's becomeKey
  override func becomeKey() {
    super.becomeKey()
    if !isPresenting && !isDismissing {
      presentDevMenu()
    }
  }

  private func presentDevMenu() {
    guard !isPresenting && !isDismissing else { return }

    isPresenting = true

    // Make sure contentViewController is loaded
    _ = devMenuViewController.view

    // Show the window and bring it to front
    self.makeKeyAndOrderFront(nil)

    // Simple fade-in animation for the dim background
    self.alphaValue = 0.0
    NSAnimationContext.runAnimationGroup({ ctx in
      ctx.duration = 0.22
      self.animator().alphaValue = 1.0
    }, completionHandler: { [weak self] in
      self?.isPresenting = false
    })
  }

  func closeBottomSheet(_ completion: (() -> Void)? = nil) {
    guard !isDismissing && !isPresenting else { return }
    isDismissing = true

    resetScrollPosition()

    // Fade out background
    NSAnimationContext.runAnimationGroup({ ctx in
      ctx.duration = 0.3
      self.animator().alphaValue = 0.0
    }, completionHandler: { [weak self] in
      guard let self = self else { return }
      self.orderOut(nil)
      self.isDismissing = false
      self.alphaValue = 1.0
      completion?()
    })
  }

  private func resetScrollPosition() {
    if let scrollView = findScrollView(in: devMenuViewController.view) {
      // Scroll to origin (top-left). AppKit's coordinate system origin is bottom-left, so this moves to (0, maxY)
      if let documentView = scrollView.documentView {
        let origin = NSPoint(x: 0, y: documentView.bounds.height - scrollView.contentView.bounds.height)
        scrollView.contentView.scroll(to: origin)
        scrollView.reflectScrolledClipView(scrollView.contentView)
      }
    }
  }

  private func findScrollView(in view: NSView) -> NSScrollView? {
    if let scrollView = view as? NSScrollView {
      return scrollView
    }

    for subview in view.subviews {
      if let scrollView = findScrollView(in: subview) {
        return scrollView
      }
    }

    return nil
  }

  // Detect clicks on the dim background (contentView) and hide the menu
  override func mouseDown(with event: NSEvent) {
    guard let content = self.contentView else {
      super.mouseDown(with: event)
      return
    }

    let locationInWindow = event.locationInWindow
    let pointInContent = content.convert(locationInWindow, from: nil)
    if let hit = content.hitTest(pointInContent), hit == content {
      manager.hideMenu()
      return
    }

    super.mouseDown(with: event)
  }
}
#else
// iOS / tvOS implementation (unchanged aside from conditional compilation)
class DevMenuWindow: UIWindow, PresentationControllerDelegate {
  private let manager: DevMenuManager
  private let devMenuViewController: DevMenuViewController
  private var isPresenting = false
  private var isDismissing = false

  required init(manager: DevMenuManager) {
    self.manager = manager
    self.devMenuViewController = DevMenuViewController(manager: manager)

    super.init(frame: UIScreen.main.bounds)

    self.rootViewController = UIViewController()
    self.backgroundColor = UIColor(white: 0, alpha: 0.4)
#if os(tvOS)
    self.windowLevel = .normal
#else
    self.windowLevel = .statusBar
#endif
    self.isHidden = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func becomeKey() {
    super.becomeKey()
    if !isPresenting && !isDismissing {
      presentDevMenu()
    }
  }

  private func presentDevMenu() {
    guard !isPresenting && !isDismissing else { return }

    guard let rootVC = self.rootViewController, rootVC.presentedViewController == nil else { return }

    guard rootVC.isViewLoaded && rootVC.view.window != nil else { return }

    isPresenting = true
#if os(tvOS)
    devMenuViewController.modalPresentationStyle = .automatic
#else
    devMenuViewController.modalPresentationStyle = .pageSheet
#endif

#if os(tvOS)
#else
    if #available(iOS 15.0, *) {
      if let sheet = devMenuViewController.sheetPresentationController {
        if #available(iOS 16.0, *) {
          sheet.detents = [
            .custom(resolver: { context in
              return context.maximumDetentValue * 0.6
            }),
            .large()
          ]
        } else {
          sheet.detents = [.medium(), .large()]
        }

        sheet.largestUndimmedDetentIdentifier = .large
        sheet.prefersEdgeAttachedInCompactHeight = true
        sheet.delegate = self
      }
    }
#endif

    rootVC.present(devMenuViewController, animated: true) { [weak self] in
      self?.isPresenting = false
    }
  }

  func closeBottomSheet(_ completion: (() -> Void)? = nil) {
    guard !isDismissing && !isPresenting else { return }
    isDismissing = true

    resetScrollPosition()
    UIView.animate(withDuration: 0.3) {
      self.backgroundColor = .clear
    }

    devMenuViewController.dismiss(animated: true) {
      self.isDismissing = false
      self.isHidden = true
      self.backgroundColor = UIColor(white: 0, alpha: 0.4)
      completion?()
    }
  }

  private func resetScrollPosition() {
    if let scrollView = findScrollView(in: devMenuViewController.view) {
      scrollView.setContentOffset(.zero, animated: false)
    }
  }

  private func findScrollView(in view: UIView) -> UIScrollView? {
    if let scrollView = view as? UIScrollView {
      return scrollView
    }

    for subview in view.subviews {
      if let scrollView = findScrollView(in: subview) {
        return scrollView
      }
    }

    return nil
  }

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    let view = super.hitTest(point, with: event)
    if view == self.rootViewController?.view && event?.type == .touches {
      manager.hideMenu()
      return self.rootViewController?.view
    }
    return view
  }

#if !os(tvOS) && !os(macOS)
  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    manager.hideMenu()
  }
#endif
}
#endif
