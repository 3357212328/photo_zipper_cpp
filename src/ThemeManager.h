#pragma once

#include <QObject>
#include <QColor>
#include <QSettings>

class ThemeManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isWarmDay READ isWarmDay WRITE setIsWarmDay NOTIFY themeChanged)

    // Window & Header backgrounds
    Q_PROPERTY(QColor windowBg READ windowBg NOTIFY themeChanged)
    Q_PROPERTY(QColor headerBg READ headerBg NOTIFY themeChanged)
    Q_PROPERTY(QColor headerBorder READ headerBorder NOTIFY themeChanged)

    // Card & Surface colors
    Q_PROPERTY(QColor cardBg READ cardBg NOTIFY themeChanged)
    Q_PROPERTY(QColor cardAltBg READ cardAltBg NOTIFY themeChanged)
    Q_PROPERTY(QColor cardBorder READ cardBorder NOTIFY themeChanged)
    Q_PROPERTY(QColor cardHoverBorder READ cardHoverBorder NOTIFY themeChanged)

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

    // Primary Accent (Warm Amber/Terracotta in Daylight vs Crisp Blue in Dark)
    Q_PROPERTY(QColor accent READ accent NOTIFY themeChanged)
    Q_PROPERTY(QColor accentHover READ accentHover NOTIFY themeChanged)
    Q_PROPERTY(QColor accentSoftBg READ accentSoftBg NOTIFY themeChanged)
    Q_PROPERTY(QColor accentSoftBorder READ accentSoftBorder NOTIFY themeChanged)
    Q_PROPERTY(QColor accentSoftText READ accentSoftText NOTIFY themeChanged)

    // Secondary Button
    Q_PROPERTY(QColor btnSecBg READ btnSecBg NOTIFY themeChanged)
    Q_PROPERTY(QColor btnSecHoverBg READ btnSecHoverBg NOTIFY themeChanged)
    Q_PROPERTY(QColor btnSecBorder READ btnSecBorder NOTIFY themeChanged)

    // Status Badges (Success / Danger)
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

    QColor windowBg() const        { return m_isWarmDay ? QColor("#F6EFE5") : QColor("#16181D"); }
    QColor headerBg() const        { return m_isWarmDay ? QColor("#EDE3D3") : QColor("#111318"); }
    QColor headerBorder() const    { return m_isWarmDay ? QColor("#DCCEB8") : QColor("#222630"); }

    QColor cardBg() const          { return m_isWarmDay ? QColor("#FFFDF9") : QColor("#22262F"); }
    QColor cardAltBg() const       { return m_isWarmDay ? QColor("#F2E9DC") : QColor("#1C2028"); }
    QColor cardBorder() const      { return m_isWarmDay ? QColor("#DFD3C0") : QColor("#2E3440"); }
    QColor cardHoverBorder() const { return m_isWarmDay ? QColor("#C6B397") : QColor("#434C5E"); }

    QColor inputBg() const         { return m_isWarmDay ? QColor("#FAF5EC") : QColor("#1A1D24"); }
    QColor inputHoverBg() const    { return m_isWarmDay ? QColor("#F1E8D9") : QColor("#212630"); }
    QColor inputFocusBg() const    { return m_isWarmDay ? QColor("#FFFFFF") : QColor("#1D2330"); }
    QColor inputDisabledBg() const { return m_isWarmDay ? QColor("#EDE6DA") : QColor("#16191F"); }
    QColor inputBorder() const     { return m_isWarmDay ? QColor("#D2C4AE") : QColor("#363C49"); }
    QColor popupBg() const         { return m_isWarmDay ? QColor("#FFFDF9") : QColor("#1E222A"); }

    QColor textPrimary() const     { return m_isWarmDay ? QColor("#2B2118") : QColor("#F1F5F9"); }
    QColor textSecondary() const   { return m_isWarmDay ? QColor("#695A4C") : QColor("#94A3B8"); }
    QColor textMuted() const       { return m_isWarmDay ? QColor("#9A8876") : QColor("#64748B"); }

    QColor accent() const          { return m_isWarmDay ? QColor("#D97706") : QColor("#3B82F6"); }
    QColor accentHover() const     { return m_isWarmDay ? QColor("#EA580C") : QColor("#60A5FA"); }
    QColor accentSoftBg() const    { return m_isWarmDay ? QColor("#FEF3C7") : QColor("#1E3A8A"); }
    QColor accentSoftBorder() const{ return m_isWarmDay ? QColor("#F59E0B") : QColor("#3B82F6"); }
    QColor accentSoftText() const  { return m_isWarmDay ? QColor("#B45309") : QColor("#93C5FD"); }

    QColor btnSecBg() const        { return m_isWarmDay ? QColor("#ECE2D0") : QColor("#252A34"); }
    QColor btnSecHoverBg() const   { return m_isWarmDay ? QColor("#E2D5BE") : QColor("#2E3543"); }
    QColor btnSecBorder() const    { return m_isWarmDay ? QColor("#CFC0A8") : QColor("#373E4C"); }

    QColor successBg() const       { return m_isWarmDay ? QColor("#DCFCE7") : QColor("#14532D"); }
    QColor successBorder() const   { return m_isWarmDay ? QColor("#86EFAC") : QColor("#234733"); }
    QColor successText() const     { return m_isWarmDay ? QColor("#15803D") : QColor("#86EFAC"); }

    QColor dangerBg() const        { return m_isWarmDay ? QColor("#FEE2E2") : QColor("#4C1D24"); }
    QColor dangerBorder() const    { return m_isWarmDay ? QColor("#FCA5A5") : QColor("#F43F5E"); }
    QColor dangerText() const      { return m_isWarmDay ? QColor("#B91C1C") : QColor("#FDA4AF"); }

    QColor rowBg() const           { return m_isWarmDay ? QColor("#FFFDF9") : QColor("#20242D"); }
    QColor rowHoverBg() const      { return m_isWarmDay ? QColor("#F8F1E5") : QColor("#252B36"); }
    QColor rowSelectedBg() const   { return m_isWarmDay ? QColor("#FEF3C7") : QColor("#223046"); }

signals:
    void themeChanged();

private:
    bool m_isWarmDay = false;
};
