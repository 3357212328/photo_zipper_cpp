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
    void setIsWarmDay(bool val) {
        if (m_isWarmDay == val) return;
        m_isWarmDay = val;
        QSettings settings(QStringLiteral("PhotoZipper"), QStringLiteral("PhotoZipperCpp"));
        settings.setValue(QStringLiteral("ui/isWarmDay"), m_isWarmDay);
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

    QColor windowBg() const        { return m_isWarmDay ? QColor("#F4EEE4") : QColor("#0E1015"); }
    QColor headerBg() const        { return m_isWarmDay ? QColor("#F4EEE4") : QColor("#0F1117"); }
    QColor sidebarBg() const       { return m_isWarmDay ? QColor("#FAF6EF") : QColor("#14171F"); }
    QColor headerBorder() const    { return m_isWarmDay ? QColor("#E5DCCD") : QColor("#202533"); }

    QColor cardBg() const          { return m_isWarmDay ? QColor("#FFFDF9") : QColor("#191D27"); }
    QColor cardAltBg() const       { return m_isWarmDay ? QColor("#EFE8DC") : QColor("#12151C"); }
    QColor cardBorder() const      { return m_isWarmDay ? QColor("#E5DCCD") : QColor("#222736"); }
    QColor cardHoverBorder() const { return m_isWarmDay ? QColor("#CFC2AE") : QColor("#333B4F"); }
    QColor surfaceElevated() const { return m_isWarmDay ? QColor("#F2EAE0") : QColor("#202534"); }

    QColor inputBg() const         { return m_isWarmDay ? QColor("#FAF6EF") : QColor("#11141B"); }
    QColor inputHoverBg() const    { return m_isWarmDay ? QColor("#F2EAE0") : QColor("#181C26"); }
    QColor inputFocusBg() const    { return m_isWarmDay ? QColor("#FFFFFF") : QColor("#161B26"); }
    QColor inputDisabledBg() const { return m_isWarmDay ? QColor("#EDE6DA") : QColor("#12141A"); }
    QColor inputBorder() const     { return m_isWarmDay ? QColor("#DDD2C1") : QColor("#272D3E"); }
    QColor popupBg() const         { return m_isWarmDay ? QColor("#FFFDF9") : QColor("#1A1E29"); }

    QColor textPrimary() const     { return m_isWarmDay ? QColor("#241C16") : QColor("#F4F6FA"); }
    QColor textSecondary() const   { return m_isWarmDay ? QColor("#6B5D50") : QColor("#94A0B8"); }
    QColor textMuted() const       { return m_isWarmDay ? QColor("#9E8F80") : QColor("#5D677D"); }

    QColor accent() const          { return m_isWarmDay ? QColor("#D46A28") : QColor("#6366F1"); }
    QColor accentHover() const     { return m_isWarmDay ? QColor("#C2591A") : QColor("#818CF8"); }
    QColor accentEnd() const       { return m_isWarmDay ? QColor("#E38B3A") : QColor("#3B82F6"); }
    QColor accentSoftBg() const    { return m_isWarmDay ? QColor("#FBEAD8") : QColor("#1E2242"); }
    QColor accentSoftBorder() const{ return m_isWarmDay ? QColor("#E6A972") : QColor("#4F46E5"); }
    QColor accentSoftText() const  { return m_isWarmDay ? QColor("#A84A14") : QColor("#A5B4FC"); }

    QColor btnSecBg() const        { return m_isWarmDay ? QColor("#EFE8DC") : QColor("#1C202B"); }
    QColor btnSecHoverBg() const   { return m_isWarmDay ? QColor("#E6DDD0") : QColor("#252B3A"); }
    QColor btnSecBorder() const    { return m_isWarmDay ? QColor("#DDD2C1") : QColor("#2C3345"); }

    QColor successBg() const       { return m_isWarmDay ? QColor("#E6F5EC") : QColor("#0F291E"); }
    QColor successBorder() const   { return m_isWarmDay ? QColor("#9BD4B4") : QColor("#1F5E42"); }
    QColor successText() const     { return m_isWarmDay ? QColor("#16794B") : QColor("#4ADE80"); }

    QColor dangerBg() const        { return m_isWarmDay ? QColor("#FCEAEA") : QColor("#2F1519"); }
    QColor dangerBorder() const    { return m_isWarmDay ? QColor("#F2B4B4") : QColor("#7F2330"); }
    QColor dangerText() const      { return m_isWarmDay ? QColor("#B92B2B") : QColor("#FB7185"); }

    QColor rowBg() const           { return m_isWarmDay ? QColor("#FFFDF9") : QColor("#171B24"); }
    QColor rowHoverBg() const      { return m_isWarmDay ? QColor("#F7F1E7") : QColor("#1E2330"); }
    QColor rowSelectedBg() const   { return m_isWarmDay ? QColor("#FBEAD8") : QColor("#1E2540"); }

signals:
    void themeChanged();

private:
    bool m_isWarmDay = false;
};
