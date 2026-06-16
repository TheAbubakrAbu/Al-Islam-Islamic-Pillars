import SwiftUI

extension View {
    @ViewBuilder
    func adaptiveSafeArea<InsetContent: View>(edge: VerticalEdge, @ViewBuilder content: () -> InsetContent) -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            self.safeAreaBar(edge: edge) {
                content()
            }
        } else {
            self.safeAreaInset(edge: edge) {
                content()
            }
        }
        #else
        self.safeAreaInset(edge: edge) {
            content()
        }
        #endif
    }

    func applyConditionalListStyle(defaultView: Bool) -> some View {
        modifier(ConditionalListStyle(defaultView: defaultView))
    }

    /// Pins the Now Playing bar to the bottom of a view as a real safe-area inset (so list content insets
    /// instead of being covered). No-op on watchOS, which surfaces Now Playing as its own list section.
    func withNowPlayingInset() -> some View {
        modifier(NowPlayingInsetModifier())
    }

    /// Tints list rows for the Sepia / Gray reading themes. Apply this to the rows/sections INSIDE a `List`
    /// (not to the `List` itself) — `.listRowBackground` only propagates when attached to row content, which
    /// is why the list-level version in `ConditionalListStyle` couldn't color the cells.
    func themedListRowBackground() -> some View {
        modifier(ThemedListRowBackground())
    }

    @ViewBuilder
    func compactListSectionSpacing() -> some View {
        #if os(iOS)
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, *) {
            self.listSectionSpacing(.compact)
        } else {
            self
        }
        #else
        self
        #endif
    }

    func endEditing() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    func dismissKeyboardOnScroll() -> some View {
        modifier(DismissKeyboardOnScrollModifier())
    }

    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V {
        block(self)
    }
    
    @ViewBuilder
    func topContentMargin(_ length: CGFloat? = 0) -> some View {
        if #available(iOS 17.0, watchOS 10.0, *) {
            self.contentMargins(.top, length)
        } else {
            self
        }
    }
}

/// Vertical spacing between views inside `safeAreaInset` stacks: iOS 26+ uses tighter 8pt; older systems use 16pt.
enum SafeAreaInsetVStackSpacing {
    static var standard: CGFloat {
        if #available(iOS 26.0, watchOS 26.0, *) {
            return 8
        }
        return 12
    }
}

struct ConditionalListStyle: ViewModifier {
    @EnvironmentObject private var settings: Settings
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.customColorScheme) private var customColorScheme

    let defaultView: Bool

    private var currentColorScheme: ColorScheme {
        settings.colorScheme ?? systemColorScheme
    }

    func body(content: Content) -> some View {
        Group {
            #if os(iOS)
            styledContent(content)
                .navigationBarTitleDisplayMode(.inline)
            #else
            content
            #endif
        }
        .accentColor(settings.accentColor.color)
        .tint(settings.accentColor.color)
        .dismissKeyboardOnScroll()
        .topContentMargin(0)
    }

    #if os(iOS)
    @ViewBuilder
    private func styledContent(_ content: Content) -> some View {
        let base = defaultView ? AnyView(content) : AnyView(content.listStyle(.plain))

        if settings.hasCustomThemeColors, #available(iOS 16.0, *) {
            // Sepia / Gray reading themes: hide the system list background and paint our own warm/neutral
            // background and row colors so the look carries across every screen that uses this list style.
            base
                .scrollContentBackground(.hidden)
                .listRowBackground(settings.themeRowBackgroundColor ?? Color(.secondarySystemGroupedBackground))
                .background((settings.themeBackgroundColor ?? Color(.systemGroupedBackground)).ignoresSafeArea())
        } else if defaultView {
            base
        } else {
            base.background(currentColorScheme == .dark ? Color.black : Color.white)
        }
    }
    #endif
}

/// Bottom Now Playing inset for iOS. On watchOS this is a no-op (Now Playing is shown as a list section),
/// which keeps `withNowPlayingInset()` callable from the shared views compiled into the Watch target.
struct NowPlayingInsetModifier: ViewModifier {
    #if os(iOS)
    @EnvironmentObject private var quranPlayer: QuranPlayer
    #endif

    func body(content: Content) -> some View {
        #if os(iOS)
        content.safeAreaInset(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                if quranPlayer.isPlaying || quranPlayer.isPaused {
                    NowPlayingView()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .background(Color.white.opacity(0.00001))
            .animation(.easeInOut, value: quranPlayer.isPlaying || quranPlayer.isPaused)
        }
        #else
        content
        #endif
    }
}

/// Paints the per-row background for the Sepia / Gray reading themes. Must be applied to rows/sections inside
/// a `List` so `.listRowBackground` actually reaches the cells. No-op for Light/Dark/System (system colors).
struct ThemedListRowBackground: ViewModifier {
    @EnvironmentObject private var settings: Settings

    @ViewBuilder
    func body(content: Content) -> some View {
        if settings.hasCustomThemeColors, let rowColor = settings.themeRowBackgroundColor {
            content.listRowBackground(rowColor)
        } else {
            content
        }
    }
}

struct DismissKeyboardOnScrollModifier: ViewModifier {
    func body(content: Content) -> some View {
        Group {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                content.scrollDismissesKeyboard(.immediately)
            } else {
                content.gesture(
                    DragGesture().onChanged { _ in
                        dismissKeyboard()
                    }
                )
            }
            #else
            content
            #endif
        }
    }

    private func dismissKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}
