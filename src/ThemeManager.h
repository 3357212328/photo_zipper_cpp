#pragma once

#include <QObject>
#include <QColor>
#include <QSettings>
#include <QWindow>

#ifdef Q_OS_WIN
#include <windows.h>
#include <dwmapi.h>
#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif
#ifndef DWMWA_BORDER_COLOR
#define DWMWA_BORDER_COLOR 34
#endif
#ifndef DWMWA_CAPTION_COLOR
#define DWMWA_CAPTION_COLOR 35
#endif
#ifndef DWMWA_TEXT_COLOR
#define DWMWA_TEXT_COLOR 36
#endif
#endif

class ThemeManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isWarmDay READ isWarmDay WRITE setIsWarmDay NOTIFY themeChanged)

    // Window & Header backgrounds
    Q_PROPERTY(QColor windowBg READ windowBg NOTIFY themeChanged)
    Q_PROPERTY(QColor headerBg READ headerBg NOTIFY themeChanged)
    Q_PROPERTY(QColor sidebarBg READ sidebarBg NOTIFY themeChanged)
    Q_PROPERTY(QColor headerBorder READ headerBorder NOTIFY themeChanged)

    // Card & Surface colors
    Q_PROPERTY(QColor cardBg READ cardBg NOTIFY themeChanged)
    Q_PROPERTY(QColor cardAltBg READ cardAltBg NOTIFY themeChanged)
    Q_PROPERTY(QColor cardBorder READ cardBorder NOTIFY themeChanged)
    Q_PROPERTY(QColor cardHoverBorder READ cardHoverBorder NOTIFY themeChanged)
    Q_PROPERTY(QColor surfaceElevated READ surfaceElevated NOTIFY themeChanged)

    // Input & Control surfaces
    Q_PROPERTY(QColor inputBg READ inputBg NOTIFY themeChanged)
    Q_PROPERTY(QColor inputHoverBg READ inputHoverBg NOTIFY themeChanged)
    Q_PROPERTY(QColor inputFocusBg READ inputFocusBg NOTIFY themeChanged)
    Q_PROPERTY(QColor inputDisabledBg READ inputDisabledBg NOTIFY themeChanged)
    Q_PROPERTY(QColor inputBorder READ inputBorder NOTIFY themeChanged)
    Q_PROPERTY(QColor popupBg READ popupBg NOTIFY themeChanged)

    // Typography colors
    Q_PROPERTY(QColor textPrimary READ textPrimary NOTIFY themeChanged)
    Q_PROPERTY(QColor textSecondary READ textSecondary NOTIFY themeChanged)
    Q_PROPERTY(QColor textMuted READ textMuted NOTIFY themeChanged)

    // Primary Accent
    Q_PROPERTY(QColor accent READ accent NOTIFY themeChanged)
    Q_PROPERTY(QColor accentHover READ accentHover NOTIFY themeChanged)
    Q_PROPERTY(QColor accentEnd READ accentEnd NOTIFY themeChanged)
    Q_PROPERTY(QColor accentSoftBg READ accentSoftBg NOTIFY themeChanged)
    Q_PROPERTY(QColor accentSoftBorder READ accentSoftBorder NOTIFY themeChanged)
    Q_PROPERTY(QColor accentSoftText READ accentSoftText NOTIFY themeChanged)

    // Secondary Button
    Q_PROPERTY(QColor btnSecBg READ btnSecBg NOTIFY themeChanged)
    Q_PROPERTY(QColor btnSecHoverBg READ btnSecHoverBg NOTIFY themeChanged)
    Q_PROPERTY(QColor btnSecBorder READ btnSecBorder NOTIFY themeChanged)

    // Status Badges
    Q_PROPERTY(QColor successBg READ successBg NOTIFY themeChanged)
    Q_PROPERTY(QColor successBorder READ successBorder NOTIFY themeChanged)
    Q_PROPERTY(QColor successText READ successText NOTIFY themeChanged)

    Q_PROPERTY(QColor dangerBg READ dangerBg NOTIFY themeChanged)
    Q_PROPERTY(QColor dangerBorder READ dangerBorder NOTIFY themeChanged)
    Q_PROPERTY(QColor dangerText READ dangerText NOTIFY themeChanged)

    // List Item states
    Q_PROPERTY(QColor rowBg READ rowBg NOTIFY themeChanged)
    Q_PROPERTY(QColor rowHoverBg READ rowHoverBg NOTIFY themeChanged)
    Q_PROPERTY(QColor rowSelectedBg READ rowSelectedBg NOTIFY themeChanged)

public:
    explicit ThemeManager(QObject* parent = nullptr) : QObject(parent) {
        QSettings settings(QStringLiteral("PhotoZipper"), QStringLiteral("PhotoZipperCpp"));
        m_isWarmDay = settings.value(QStringLiteral("ui/isWarmDay"), false).toBool();
    }

    bool isWarmDay() const { return m_isWarmDay; }
    Q_INVOKABLE void setIsWarmDay(bool val, bool persist = true) {
        if (m_isWarmDay == val) return;
        m_isWarmDay = val;
        if (persist) {
            QSettings settings(QStringLiteral("PhotoZipper"), QStringLiteral("PhotoZipperCpp"));
            settings.setValue(QStringLiteral("ui/isWarmDay"), m_isWarmDay);
        }
        emit themeChanged();
    }

    Q_INVOKABLE void toggle() { setIsWarmDay(!m_isWarmDay); }

    Q_INVOKABLE void applyWindowTheme(QWindow* window) const {
#ifdef Q_OS_WIN
        if (!window) return;
        HWND hwnd = reinterpret_cast<HWND>(window->winId());
        if (!hwnd) return;

        BOOL useDark = m_isWarmDay ? FALSE : TRUE;
        DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &useDark, sizeof(useDark));

        const QColor cap = headerBg();
        COLORREF captionColor = RGB(cap.red(), cap.green(), cap.blue());
        DwmSetWindowAttribute(hwnd, DWMWA_CAPTION_COLOR, &captionColor, sizeof(captionColor));

        const QColor txt = textPrimary();
        COLORREF textColor = RGB(txt.red(), txt.green(), txt.blue());
        DwmSetWindowAttribute(hwnd, DWMWA_TEXT_COLOR, &textColor, sizeof(textColor));

        const QColor brd = headerBorder();
        COLORREF borderColor = RGB(brd.red(), brd.green(), brd.blue());
        DwmSetWindowAttribute(hwnd, DWMWA_BORDER_COLOR, &borderColor, sizeof(borderColor));
#else
        Q_UNUSED(window);
#endif
    }

    QColor windowBg() const        { return m_isWarmDay ? QColor("#F4EEE4") : QColor("#0D0F14"); }
    QColor headerBg() const        { return m_isWarmDay ? QColor("#F4EEE4") : QColor("#12151D"); }
    QColor sidebarBg() const       { return m_isWarmDay ? QColor("#FAF6EF") : QColor("#151822"); }
    QColor headerBorder() const    { return m_isWarmDay ? QColor("#E5DCCD") : QColor("#283044"); }

    QColor cardBg() const          { return m_isWarmDay ? QColor("#FFFDF9") : QColor("#1B202C"); }
    QColor cardAltBg() const       { return m_isWarmDay ? QColor("#EFE8DC") : QColor("#11141B"); }
    QColor cardBorder() const      { return m_isWarmDay ? QColor("#E5DCCD") : QColor("#2C344A"); }
    QColor cardHoverBorder() const { return m_isWarmDay ? QColor("#CFC2AE") : QColor("#495676"); }
    QColor surfaceElevated() const { return m_isWarmDay ? QColor("#F2EAE0") : QColor("#293247"); }

    QColor inputBg() const         { return m_isWarmDay ? QColor("#FAF6EF") : QColor("#0F1219"); }
    QColor inputHoverBg() const    { return m_isWarmDay ? QColor("#F2EAE0") : QColor("#191E2A"); }
    QColor inputFocusBg() const    { return m_isWarmDay ? QColor("#FFFFFF") : QColor("#161C29"); }
    QColor inputDisabledBg() const { return m_isWarmDay ? QColor("#EDE6DA") : QColor("#13161F"); }
    QColor inputBorder() const     { return m_isWarmDay ? QColor("#DDD2C1") : QColor("#38425B"); }
    QColor popupBg() const         { return m_isWarmDay ? QColor("#FFFDF9") : QColor("#1C212E"); }

    QColor textPrimary() const     { return m_isWarmDay ? QColor("#241C16") : QColor("#F8FAFC"); }
    QColor textSecondary() const   { return m_isWarmDay ? QColor("#6B5D50") : QColor("#CBD5E1"); }
    QColor textMuted() const       { return m_isWarmDay ? QColor("#9E8F80") : QColor("#94A3B8"); }

    QColor accent() const          { return m_isWarmDay ? QColor("#D46A28") : QColor("#5B7CFA"); }
    QColor accentHover() const     { return m_isWarmDay ? QColor("#C2591A") : QColor("#7491FF"); }
    QColor accentEnd() const       { return m_isWarmDay ? QColor("#E38B3A") : QColor("#3B82F6"); }
    QColor accentSoftBg() const    { return m_isWarmDay ? QColor("#FBEAD8") : QColor("#243461"); }
    QColor accentSoftBorder() const{ return m_isWarmDay ? QColor("#E6A972") : QColor("#6988FF"); }
    QColor accentSoftText() const  { return m_isWarmDay ? QColor("#A84A14") : QColor("#E6EEFF"); }

    QColor btnSecBg() const        { return m_isWarmDay ? QColor("#EFE8DC") : QColor("#23293A"); }
    QColor btnSecHoverBg() const   { return m_isWarmDay ? QColor("#E6DDD0") : QColor("#2E374D"); }
    QColor btnSecBorder() const    { return m_isWarmDay ? QColor("#DDD2C1") : QColor("#3C4763"); }

    QColor successBg() const       { return m_isWarmDay ? QColor("#E6F5EC") : QColor("#113022"); }
    QColor successBorder() const   { return m_isWarmDay ? QColor("#9BD4B4") : QColor("#256F4D"); }
    QColor successText() const     { return m_isWarmDay ? QColor("#16794B") : QColor("#5EEB98"); }

    QColor dangerBg() const        { return m_isWarmDay ? QColor("#FCEAEA") : QColor("#38181E"); }
    QColor dangerBorder() const    { return m_isWarmDay ? QColor("#F2B4B4") : QColor("#942B3B"); }
    QColor dangerText() const      { return m_isWarmDay ? QColor("#B92B2B") : QColor("#FDA4AF"); }

    QColor rowBg() const           { return m_isWarmDay ? QColor("#FFFDF9") : QColor("#181D28"); }
    QColor rowHoverBg() const      { return m_isWarmDay ? QColor("#F7F1E7") : QColor("#202736"); }
    QColor rowSelectedBg() const   { return m_isWarmDay ? QColor("#FBEAD8") : QColor("#223055"); }

signals:
    void themeChanged();

private:
    bool m_isWarmDay = false;
};
