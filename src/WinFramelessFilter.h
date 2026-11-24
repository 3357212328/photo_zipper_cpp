#pragma once

#include <QAbstractNativeEventFilter>
#include <QByteArray>
#include <QCoreApplication>
#include <QPointer>
#include <QWindow>

#ifdef Q_OS_WIN
#include <windows.h>
#include <windowsx.h>
#include <dwmapi.h>
#ifndef DWMWA_WINDOW_CORNER_PREFERENCE
#define DWMWA_WINDOW_CORNER_PREFERENCE 33
#endif
#ifndef DWMWCP_ROUND
#define DWMWCP_ROUND 2
#endif
#endif

class WinFramelessFilter : public QAbstractNativeEventFilter {
public:
    explicit WinFramelessFilter(QWindow* window)
        : m_window(window)
    {
#ifdef Q_OS_WIN
        if (m_window) {
            m_hwnd = reinterpret_cast<HWND>(m_window->winId());
        }
#endif
    }

    ~WinFramelessFilter() override
    {
        if (auto* app = QCoreApplication::instance()) {
            app->removeNativeEventFilter(this);
        }
    }

    static void setupWindow(QWindow* window)
    {
#ifdef Q_OS_WIN
        if (!window) return;
        HWND hwnd = reinterpret_cast<HWND>(window->winId());
        if (!hwnd) return;

        // Keep WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU
        // so Windows 11 rounded corners, Aero Snap, and DWM animations continue to work.
        LONG_PTR style = GetWindowLongPtrW(hwnd, GWL_STYLE);
        style |= (WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
        SetWindowLongPtrW(hwnd, GWL_STYLE, style);

        MARGINS margins = {0, 0, 1, 0};
        DwmExtendFrameIntoClientArea(hwnd, &margins);

        DWORD cornerPref = DWMWCP_ROUND;
        DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE, &cornerPref, sizeof(cornerPref));

        SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
                     SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
#else
        Q_UNUSED(window);
#endif
    }

    bool nativeEventFilter(const QByteArray& eventType, void* message, qintptr* result) override
    {
#ifdef Q_OS_WIN
        if (!m_window || !m_hwnd || eventType != "windows_generic_MSG" || !message) {
            return false;
        }
        MSG* msg = static_cast<MSG*>(message);
        if (msg->hwnd != m_hwnd) {
            return false;
        }

        if (msg->message == WM_NCDESTROY) {
            m_hwnd = nullptr;
            return false;
        }

        if (msg->message == WM_NCCALCSIZE) {
            if (msg->wParam == TRUE && msg->lParam != 0) {
                if (IsZoomed(msg->hwnd)) {
                    auto* params = reinterpret_cast<NCCALCSIZE_PARAMS*>(msg->lParam);
                    const UINT dpi = GetDpiForWindow(msg->hwnd);
                    const int cx = GetSystemMetricsForDpi(SM_CXFRAME, dpi) + GetSystemMetricsForDpi(SM_CXPADDEDBORDER, dpi);
                    const int cy = GetSystemMetricsForDpi(SM_CYFRAME, dpi) + GetSystemMetricsForDpi(SM_CXPADDEDBORDER, dpi);
                    params->rgrc[0].left += cx;
                    params->rgrc[0].right -= cx;
                    params->rgrc[0].top += cy;
                    params->rgrc[0].bottom -= cy;
                }
                if (result) *result = 0;
                return true;
            }
            return false;
        }

        if (msg->message == WM_NCHITTEST) {
            if (!IsZoomed(msg->hwnd)) {
                RECT winRect{};
                if (GetWindowRect(msg->hwnd, &winRect)) {
                    const int x = GET_X_LPARAM(msg->lParam);
                    const int y = GET_Y_LPARAM(msg->lParam);
                    const int border = qMax(6, qRound(6.0 * m_window->devicePixelRatio()));

                    const bool onLeft   = (x >= winRect.left && x < winRect.left + border);
                    const bool onRight  = (x < winRect.right && x >= winRect.right - border);
                    const bool onTop    = (y >= winRect.top && y < winRect.top + border);
                    const bool onBottom = (y < winRect.bottom && y >= winRect.bottom - border);

                    LRESULT hit = HTNOWHERE;
                    if (onTop && onLeft)         hit = HTTOPLEFT;
                    else if (onTop && onRight)   hit = HTTOPRIGHT;
                    else if (onBottom && onLeft) hit = HTBOTTOMLEFT;
                    else if (onBottom && onRight)hit = HTBOTTOMRIGHT;
                    else if (onLeft)             hit = HTLEFT;
                    else if (onRight)            hit = HTRIGHT;
                    else if (onTop)              hit = HTTOP;
                    else if (onBottom)           hit = HTBOTTOM;

                    if (hit != HTNOWHERE) {
                        if (result) *result = hit;
                        return true;
                    }
                }
            }
            return false;
        }
#else
        Q_UNUSED(eventType);
        Q_UNUSED(message);
        Q_UNUSED(result);
#endif
        return false;
    }

private:
    QPointer<QWindow> m_window;
#ifdef Q_OS_WIN
    HWND m_hwnd = nullptr;
#endif
};
