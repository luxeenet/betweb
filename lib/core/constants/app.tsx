import { useState, useEffect, useCallback, useRef, lazy, Suspense } from "react"
import { addSubscribedTipster, removeSubscribedTipster, getCurrentUser, logoutUser, restoreSession, flushPendingSubscriptions } from "@/lib/storage"
import { clearAdminSession, clearOwnerSession } from "@/lib/admin"
import SplashScreen from "@/components/splash-screen"
import AuthScreen from "@/components/auth-screen"
import BottomNav from "@/components/bottom-nav"
import HomePage from "@/components/home-page"
import BetslipsPage from "@/components/betslips-page"
import BetslipDetailPage from "@/components/betslip-detail-page"
import TipsterProfilePage from "@/components/tipster-profile-page"
import SubscriptionPage from "@/components/subscription-page"
import AccountPage from "@/components/account-page"
import PaymentPage from "@/components/payment-page"
import HistoryPage from "@/components/history-page"
import StatisticsPage from "@/components/statistics-page"
import TopRatedPage from "@/components/top-rated-page"
import AllTipstersPage from "@/components/all-tipsters-page"
import AdminPanel from "@/components/admin-panel"
import ManagementAdminPanel from "@/components/management-admin-panel"
import WelcomeBanner from "@/components/welcome-banner"

// Lazy-load the Owner Dashboard so its heavy dependencies (Recharts) are NOT
// shipped in the main bundle for regular users.
const OwnerDashboard = lazy(() => import("@/components/owner-dashboard"))

import type { Tipster } from "@/lib/data"

type Page = "home" | "betslips" | "subscription" | "account"

export default function BetMakiniApp() {
    const [showSplash, setShowSplash] = useState(true)
    const [isAuthenticated, setIsAuthenticated] = useState(false)
    const [authChecked, setAuthChecked] = useState(false)
    const [activePage, setActivePage] = useState<Page>("home")
    const [showAdmin, setShowAdmin] = useState(false)
    const [showOwner, setShowOwner] = useState(false)
    // Owner-only mode — when true, show ONLY Owner Dashboard (no regular app)
    const [isOwnerMode, setIsOwnerMode] = useState(false)
    const [refreshKey, setRefreshKey] = useState(0)

    // Tipsters data - pakiwa wakati wa splash screen
    const [topTipsters, setTopTipsters] = useState<Tipster[]>([])
    const [followTipsters, setFollowTipsters] = useState<Tipster[]>([])
    const [dataLoaded, setDataLoaded] = useState(false)

    const [swipeProgress, setSwipeProgress] = useState(0)
    const swipeStartX = useRef(0)
    const swipeStartY = useRef(0)
    const isSwipingBack = useRef(false)

    // Overlay states
    const [showDetail, setShowDetail] = useState<string | null>(null)
    const [showProfile, setShowProfile] = useState<string | null>(null)
    const [showPayment, setShowPayment] = useState<string | null>(null)
    const [showPaymentGeneral, setShowPaymentGeneral] = useState(false)
    const [showHistory, setShowHistory] = useState(false)
    const [showStats, setShowStats] = useState(false)
    const [showTopRated, setShowTopRated] = useState(false)
    const [showAllTipsters, setShowAllTipsters] = useState(false)

    const [unlockKey, setUnlockKey] = useState(0)
    const [activeBetTab, setActiveBetTab] = useState<'betofday' | 'extrabet' | 'rollover'>('betofday')
    const [hideBottomNav, setHideBottomNav] = useState(false)

    // Native WebView App Detection
    const [isNativeApp, setIsNativeApp] = useState(false)

    useEffect(() => {
        if (typeof window !== "undefined") {
            const isNative = navigator.userAgent.includes("PremiumApp") || (window as any).isNativeApp === true;
            setIsNativeApp(isNative);
        }
    }, []);

    // PostMessage interface to communicate with the Flutter WebView client
    const sendNativeMessage = useCallback((action: string, data: any) => {
        try {
            if ((window as any).FlutterNavigation) {
                (window as any).FlutterNavigation.postMessage(JSON.stringify({ action, ...data }));
            }
        } catch (e) {
            console.warn("Failed to dispatch native message:", e);
        }
    }, []);

    // Preload images function
    const preloadImages = (urls: string[]): Promise<void[]> => {
        return Promise.all(
            urls.map((url) => {
                return new Promise<void>((resolve) => {
                    if (!url) {
                        resolve()
                        return
                    }
                    const img = new Image()
                    img.onload = () => resolve()
                    img.onerror = () => resolve() // Continue even if image fails
                    img.src = url
                })
            })
        )
    }

    // Load data na auth check wakati wa splash
    useEffect(() => {
        const init = async () => {
            // Restore session from HTTP-only cookie (persistent login via JWT)
            // This also syncs subscriptions from DB to localStorage
            const user = await restoreSession()
            const hasUser = !!user

            // Retry any subscriptions that never reached the database
            if (hasUser) {
                flushPendingSubscriptions().catch(() => { })
                // Bump refreshKey so all components re-read localStorage subscriptions
                // This ensures TipsterCard shows correct isSubscribed state after session restore
                setRefreshKey(k => k + 1)
            }

            // Load tipsters data
            let loadedTopTipsters: Tipster[] = []
            let loadedFollowTipsters: Tipster[] = []
            let bannerUrls: string[] = []

            try {
                const res = await fetch(`/api/data?t=${Date.now()}`, { cache: "no-store" })
                if (res.ok) {
                    const data = await res.json()
                    loadedTopTipsters = data.topTipsters || []
                    loadedFollowTipsters = data.followTipsters || []
                    bannerUrls = data.bannerImages?.map((b: { image: string }) => b.image) || []

                    setTopTipsters(loadedTopTipsters)
                    setFollowTipsters(loadedFollowTipsters)
                }
            } catch {
                // Keep empty on error
            }

            // Collect all image URLs to preload
            const tipsterImages = [
                ...loadedTopTipsters.map(t => t.img),
                ...loadedFollowTipsters.map(t => t.img)
            ].filter(Boolean)

            const allImages = [...bannerUrls, ...tipsterImages]

            // Preload all images in background
            await preloadImages(allImages).catch(() => { })

            setDataLoaded(true)

            // Hide splash after data and images loaded (minimum 300ms for animation)
            setTimeout(() => {
                setShowSplash(false)
                // Set auth state AFTER splash is hidden to avoid flash
                setIsAuthenticated(hasUser)
                setAuthChecked(true)
            }, 300)
        }
        init()
    }, [])

    // Session heartbeat — track live visitors for Owner Dashboard
    // Wrapped fully in try-catch: older iOS Safari / private mode can block
    // sessionStorage and crypto.randomUUID, and we never want the heartbeat to
    // crash the whole app.
    useEffect(() => {
        if (!isAuthenticated || isOwnerMode) return

        let sessionToken = ""
        try {
            sessionToken = window.sessionStorage?.getItem("sessionToken") || ""
            if (!sessionToken) {
                // randomUUID is unavailable in older Safari — fall back to a timestamp-based id
                sessionToken =
                    typeof crypto !== "undefined" && typeof crypto.randomUUID === "function"
                        ? crypto.randomUUID()
                        : `s_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 10)}`
                try {
                    window.sessionStorage?.setItem("sessionToken", sessionToken)
                } catch {
                    // ignore (private browsing / quota)
                }
            }
        } catch {
            // Any failure just skips session tracking — app must not crash
            return
        }

        const sendHeartbeat = () => {
            try {
                const user = getCurrentUser()
                fetch("/api/session/heartbeat", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        sessionToken,
                        userId: user?.id || null,
                        pagePath: typeof window !== "undefined" ? window.location.pathname : "/",
                    }),
                }).catch(() => { })
            } catch {
                // swallow
            }
        }

        sendHeartbeat()
        const interval = setInterval(sendHeartbeat, 30000)
        return () => clearInterval(interval)
    }, [isAuthenticated, isOwnerMode])

    // Background refresh every 15 seconds
    const refreshData = useCallback(async () => {
        try {
            const res = await fetch(`/api/data?t=${Date.now()}`, { cache: "no-store" })
            if (res.ok) {
                const data = await res.json()
                setTopTipsters(data.topTipsters || [])
                setFollowTipsters(data.followTipsters || [])
            }
        } catch {
            // Keep existing data on error
        }
    }, [])

    useEffect(() => {
        if (!dataLoaded) return
        const interval = setInterval(refreshData, 15000)
        return () => clearInterval(interval)
    }, [dataLoaded, refreshData])

    // Swipe gesture detection
    useEffect(() => {
        const handleTouchStart = (e: TouchEvent) => {
            const touch = e.touches[0]
            swipeStartX.current = touch.clientX
            swipeStartY.current = touch.clientY

            // Only detect swipe from left edge (within 50px)
            if (touch.clientX < 50 && (showDetail || showProfile || showPayment || showPaymentGeneral)) {
                isSwipingBack.current = true
            }
        }

        const handleTouchMove = (e: TouchEvent) => {
            if (!isSwipingBack.current) return

            const touch = e.touches[0]
            const deltaX = touch.clientX - swipeStartX.current
            const deltaY = Math.abs(touch.clientY - swipeStartY.current)

            // Only proceed if horizontal swipe is more than vertical
            if (deltaY > 50) {
                isSwipingBack.current = false
                return
            }

            if (deltaX > 0 && deltaX < 200) {
                setSwipeProgress(deltaX / 200)
                e.preventDefault()
            }
        }

        const handleTouchEnd = () => {
            if (!isSwipingBack.current) return

            // If swiped more than 50%, go back
            if (swipeProgress > 0.5) {
                if (showDetail) setShowDetail(null)
                else if (showProfile) setShowProfile(null)
                else if (showPayment) setShowPayment(null)
                else if (showPaymentGeneral) setShowPaymentGeneral(false)
            }

            setSwipeProgress(0)
            isSwipingBack.current = false
        }

        document.addEventListener('touchstart', handleTouchStart, { passive: false })
        document.addEventListener('touchmove', handleTouchMove, { passive: false })
        document.addEventListener('touchend', handleTouchEnd)

        return () => {
            document.removeEventListener('touchstart', handleTouchStart)
            document.removeEventListener('touchmove', handleTouchMove)
            document.removeEventListener('touchend', handleTouchEnd)
        }
    }, [showDetail, showProfile, showPayment, showPaymentGeneral, swipeProgress])

    const refresh = useCallback(() => setRefreshKey((k) => k + 1), [])

    const handleSubscribe = useCallback(
        (name: string, img: string, id: string, _accuracy: number) => {
            addSubscribedTipster(name, img, id)
            refresh()
        },
        [refresh]
    )

    const handleViewProfile = useCallback((id: string) => {
        setShowProfile(id)
    }, [])

    const handleUnsubscribe = useCallback(
        (name: string) => {
            removeSubscribedTipster(name)
            setShowProfile(null)
            refresh()
            alert("Umemondoa " + name + " kwenye subscription yako.")
        },
        [refresh]
    )

    const handleViewBetslipsFromProfile = useCallback((id: string) => {
        setShowDetail(null)
        setShowProfile(null)
        setRefreshKey((k) => k + 1)
        setActivePage("betslips")
        // Open the betslip detail after betslips page mounts and finishes loading
        setTimeout(() => setShowDetail(id), 1200)
    }, [])

    const handleUnlocked = useCallback((tipsterId: string) => {
        void tipsterId
        setUnlockKey((k) => k + 1)
    }, [])

    const handleNavigate = useCallback((page: Page) => {
        // Clear all overlays when navigating to a main tab
        setShowDetail(null)
        setShowProfile(null)
        setShowPayment(null)
        setShowPaymentGeneral(false)
        setShowHistory(false)
        setShowStats(false)
        // Always bump refreshKey for betslips/subscription so the component remounts and re-fetches
        if (page === 'betslips' || page === 'subscription') {
            setRefreshKey((k) => k + 1)
        }
        setActivePage(page)
    }, [])

    // Expose global callback to allow the native Flutter WebView app to trigger navigation changes
    useEffect(() => {
        if (typeof window !== "undefined") {
            (window as any).setActivePageFromNative = (page: Page) => {
                handleNavigate(page);
            };
        }
        return () => {
            if (typeof window !== "undefined") {
                delete (window as any).setActivePageFromNative;
            }
        };
    }, [handleNavigate]);

    // Synchronize the current tab selection back to the native bottom bar of the app
    useEffect(() => {
        if (isNativeApp) {
            sendNativeMessage("pageChanged", { page: activePage });
        }
    }, [activePage, isNativeApp, sendNativeMessage]);

    // Determine whether any modals, full-screen panels, or owner dashboards are active
    const shouldHideNativeBar = !!(
        showDetail ||
        showProfile ||
        showPayment ||
        showPaymentGeneral ||
        showHistory ||
        showStats ||
        showAllTipsters ||
        showTopRated ||
        showAdmin ||
        showOwner ||
        hideBottomNav
    );

    // Synchronize visibility changes of the native bottom navigation bar
    useEffect(() => {
        if (isNativeApp) {
            sendNativeMessage("toggleBottomBar", { hide: shouldHideNativeBar });
        }
    }, [shouldHideNativeBar, isNativeApp, sendNativeMessage]);

    const handleLogout = useCallback(async () => {
        await logoutUser()
        // Clear all admin/owner sessions on logout
        clearAdminSession()
        clearOwnerSession()
        setIsAuthenticated(false)
        setIsOwnerMode(false)
        setActivePage("home")
    }, [])

    const handleAuthenticated = useCallback((ownerMode?: boolean) => {
        setIsAuthenticated(true)
        // If owner logged in with owner credentials, enter owner-only mode
        if (ownerMode) {
            setIsOwnerMode(true)
        }
        // Flush any subscriptions that were queued while logged out
        flushPendingSubscriptions().catch(() => { })
        // Bump refreshKey so components re-read subscriptions from localStorage
        // (login API saves subscriptions to localStorage before this callback fires)
        setRefreshKey(k => k + 1)
    }, [])

    if (showSplash) return <SplashScreen />
    if (!authChecked) return null
    if (!isAuthenticated) return <AuthScreen onAuthenticated={handleAuthenticated} />

    // Owner-only mode — show ONLY the Owner Dashboard, no regular app UI
    if (isOwnerMode) {
        return (
            <Suspense
                fallback={
                    <div
                        style={{
                            minHeight: "100vh",
                            background: "#000",
                            color: "#fff",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            fontSize: 14,
                            fontWeight: 600,
                        }}
                    >
                        Loading Owner Dashboard...
                    </div>
                }
            >
                <OwnerDashboard onLogout={handleLogout} />
            </Suspense>
        )
    }

    return (
        <div className="pb-[64px] select-none touch-manipulation">
            {/* Welcome Banner - shows once on first login/registration */}
            <WelcomeBanner username={getCurrentUser()?.username} />

            {/* Swipe Back Indicator */}
            {swipeProgress > 0 && (
                <div
                    className="fixed left-0 top-1/2 -translate-y-1/2 z-[10000] pointer-events-none transition-opacity duration-200"
                    style={{
                        opacity: swipeProgress,
                        paddingLeft: 20,
                    }}
                >
                    <svg
                        width={32}
                        height={32}
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="#ff7b2e"
                        strokeWidth={3}
                        style={{
                            transform: `translateX(${swipeProgress * 30}px)`,
                            transition: 'transform 0.1s ease-out'
                        }}
                    >
                        <path d="M19 12H5M12 19l-7-7 7-7" />
                    </svg>
                </div>
            )}

            {/* Main Pages */}
            {activePage === "home" && (
                <HomePage
                    onSubscribe={handleSubscribe}
                    onViewProfile={handleViewProfile}
                    onOpenTopRated={() => setShowTopRated(true)}
                    onViewAllTipsters={() => setShowAllTipsters(true)}
                    refreshKey={refreshKey}
                    topTipsters={topTipsters}
                    followTipsters={followTipsters}
                />
            )}
            {activePage === "betslips" && (
                <BetslipsPage
                    key={refreshKey}
                    onViewDetail={(id) => setShowDetail(id)}
                    onShowHistory={() => setShowHistory(true)}
                    onShowStats={() => setShowStats(true)}
                    activeBetTab={activeBetTab}
                    onTabChange={setActiveBetTab}
                />
            )}
            {activePage === "subscription" && (
                <SubscriptionPage key={refreshKey} refreshKey={refreshKey} onRefresh={refresh} onViewProfile={handleViewProfile} />
            )}
            {activePage === "account" && (
                <AccountPage
                    onShowPayment={() => setShowPaymentGeneral(true)}
                    onLogout={handleLogout}
                    onOpenAdmin={() => setShowAdmin(true)}
                    onOpenOwner={() => setShowOwner(true)}
                    onHideBottomNav={setHideBottomNav}
                />
            )}

            {/* Hide the web bottom navigation while running in the native webview application context, or when modals are active */}
            {!isNativeApp && !hideBottomNav && !showAdmin && !showOwner && (
                <BottomNav activePage={activePage} onNavigate={handleNavigate} />
            )}

            {/* Overlays */}
            {showDetail && (
                <BetslipDetailPage
                    betslipId={showDetail}
                    onBack={() => setShowDetail(null)}
                    onBuy={(id) => setShowPayment(id)}
                    unlockKey={unlockKey}
                />
            )}

            {showProfile && (
                <TipsterProfilePage
                    tipsterId={showProfile}
                    onBack={() => setShowProfile(null)}
                    onUnsubscribe={(name) => {
                        removeSubscribedTipster(name)
                        setShowProfile(null)
                        setRefreshKey((k) => k + 1)
                    }}
                    onViewBetslips={handleViewBetslipsFromProfile}
                />
            )}

            {(showPayment || showPaymentGeneral) && (
                <PaymentPage
                    betslipId={showPayment}
                    tipsterId={showPayment ? showDetail : null}
                    onClose={() => {
                        setShowPayment(null)
                        setShowPaymentGeneral(false)
                    }}
                    onUnlocked={handleUnlocked}
                />
            )}

            {showHistory && <HistoryPage onClose={() => setShowHistory(false)} />}
            {showStats && <StatisticsPage onClose={() => setShowStats(false)} />}
            {showAllTipsters && (
                <AllTipstersPage
                    onBack={() => setShowAllTipsters(false)}
                    onViewProfile={(id) => {
                        setShowAllTipsters(false)
                        handleViewProfile(id)
                    }}
                />
            )}
            {showTopRated && (
                <TopRatedPage
                    onClose={() => setShowTopRated(false)}
                    onViewProfile={(id) => {
                        setShowTopRated(false)
                        handleViewProfile(id)
                    }}
                />
            )}

            {/* Admin Panel — full screen overlay */}
            {showAdmin && (
                <div className="fixed inset-0 z-[9000] overflow-y-auto" style={{ background: "#060606" }}>
                    <AdminPanel onExit={() => setShowAdmin(false)} />
                </div>
            )}

            {/* Owner/Management Panel — full screen overlay */}
            {showOwner && (
                <div className="fixed inset-0 z-[9000] overflow-y-auto" style={{ background: "#000" }}>
                    <ManagementAdminPanel onExit={() => setShowOwner(false)} />
                </div>
            )}

        </div>
    )
}
