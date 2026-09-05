const std = @import("std");

const c = @cImport({
    @cDefine("WIN32_LEAN_AND_MEAN", "1");
    @cInclude("windows.h");
});

// Helper for RGB colors without macro issues
fn rgb(r: u8, g: u8, b: u8) c.COLORREF {
    return @as(c.COLORREF, r) | (@as(c.COLORREF, g) << 8) | (@as(c.COLORREF, b) << 16);
}

const Mode = enum {
    focus,
    short_break,

    fn duration(self: Mode) u32 {
        return switch (self) {
            .focus => 25 * 60,
            .short_break => 5 * 60,
        };
    }

    fn label(self: Mode) [*:0]const u8 {
        return switch (self) {
            .focus => "FOCUS",
            .short_break => "BREAK",
        };
    }
};

// Global App State
var current_mode: Mode = .focus;
var total_seconds: u32 = 25 * 60;
var remaining_seconds: u32 = 25 * 60;
var is_running: bool = true;
var tick_half_sec: u8 = 0;
var alert_flash: bool = false;

fn windowProc(
    hwnd: c.HWND,
    msg: c.UINT,
    wparam: c.WPARAM,
    lparam: c.LPARAM,
) callconv(std.os.windows.WINAPI) c.LRESULT {
    switch (msg) {
        c.WM_TIMER => {
            tick_half_sec +%= 1;

            if (remaining_seconds > 0) {
                // Decrement once per second
                if (is_running and (tick_half_sec % 2 == 0)) {
                    remaining_seconds -= 1;
                    if (remaining_seconds == 0) {
                        _ = c.MessageBeep(c.MB_ICONEXCLAMATION);
                    }
                }
            } else {
                // Alarm phase: toggle red flash every 500ms
                alert_flash = !alert_flash;
                if (alert_flash) {
                    _ = c.MessageBeep(c.MB_ICONEXCLAMATION);
                }
            }

            _ = c.InvalidateRect(hwnd, null, c.FALSE);
            return 0;
        },

        c.WM_PAINT => {
            var ps: c.PAINTSTRUCT = undefined;
            const hdc = c.BeginPaint(hwnd, &ps);
            defer _ = c.EndPaint(hwnd, &ps);

            var rect: c.RECT = undefined;
            _ = c.GetClientRect(hwnd, &rect);
            const w = rect.right;
            const h = rect.bottom;

            // 1. Determine colors based on state
            const is_expired = (remaining_seconds == 0);
            var bg_color = rgb(22, 24, 29); // Dark background default
            var text_color = if (current_mode == .focus) rgb(56, 189, 248) else rgb(192, 132, 252);

            if (is_expired) {
                bg_color = if (alert_flash) rgb(220, 38, 38) else rgb(70, 10, 10);
                text_color = rgb(255, 255, 255);
            } else if (!is_running) {
                text_color = rgb(251, 191, 36); // Amber when paused
            }

            // Draw Background
            const bg_brush = c.CreateSolidBrush(bg_color);
            defer _ = c.DeleteObject(bg_brush);
            _ = c.FillRect(hdc, &rect, bg_brush);

            // 2. Draw Progress Bar (at the bottom)
            if (!is_expired and total_seconds > 0) {
                const progress_w = @divTrunc(@as(i64, remaining_seconds) * @as(i64, w), @as(i64, total_seconds));
                var bar_rect = c.RECT{
                    .left = 0,
                    .top = h - 3,
                    .right = @intCast(progress_w),
                    .bottom = h,
                };
                const bar_brush = c.CreateSolidBrush(text_color);
                defer _ = c.DeleteObject(bar_brush);
                _ = c.FillRect(hdc, &bar_rect, bar_brush);
            }

            _ = c.SetBkMode(hdc, c.TRANSPARENT);

            // 3. Render Large Timer (e.g. 24:59)
            const font_timer = c.CreateFontA(
                26, 0, 0, 0, c.FW_BOLD, 0, 0, 0,
                c.DEFAULT_CHARSET, c.OUT_DEFAULT_PRECIS, c.CLIP_DEFAULT_PRECIS,
                c.CLEARTYPE_QUALITY, c.DEFAULT_PITCH, "Segoe UI",
            );
            defer _ = c.DeleteObject(font_timer);
            const old_font = c.SelectObject(hdc, font_timer);

            var timer_buf: [16]u8 = undefined;
            const mins = remaining_seconds / 60;
            const secs = remaining_seconds % 60;
            const timer_str = std.fmt.bufPrintZ(&timer_buf, "{d:0>2}:{d:0>2}", .{ mins, secs }) catch "00:00";

            _ = c.SetTextColor(hdc, text_color);
            _ = c.TextOutA(hdc, 14, 6, timer_str.ptr, @intCast(timer_str.len));

            // 4. Render Small Status Label (e.g. FOCUS · PAUSED)
            const font_sub = c.CreateFontA(
                11, 0, 0, 0, c.FW_BOLD, 0, 0, 0,
                c.DEFAULT_CHARSET, c.OUT_DEFAULT_PRECIS, c.CLIP_DEFAULT_PRECIS,
                c.CLEARTYPE_QUALITY, c.DEFAULT_PITCH, "Segoe UI",
            );
            defer _ = c.DeleteObject(font_sub);
            _ = c.SelectObject(hdc, font_sub);

            var status_buf: [32]u8 = undefined;
            const status_str = if (is_expired)
                "TIME'S UP!"
            else if (!is_running)
                std.fmt.bufPrintZ(&status_buf, "{s} [PAUSED]", .{current_mode.label()}) catch "PAUSED"
            else
                std.fmt.bufPrintZ(&status_buf, "{s}", .{current_mode.label()}) catch "RUNNING";

            const sub_color = if (is_expired) rgb(255, 255, 255) else rgb(150, 155, 165);
            _ = c.SetTextColor(hdc, sub_color);
            _ = c.TextOutA(hdc, 16, 34, status_str.ptr, @intCast(status_str.len));

            _ = c.SelectObject(hdc, old_font);
            return 0;
        },

        // Left Click: Pause / Resume or Shift-Drag
        c.WM_LBUTTONDOWN => {
            if (c.GetKeyState(c.VK_SHIFT) < 0) {
                // Drag window with Shift held
                _ = c.ReleaseCapture();
                _ = c.SendMessageA(hwnd, c.WM_NCLBUTTONDOWN, c.HTCAPTION, 0);
            } else {
                is_running = !is_running;
                _ = c.InvalidateRect(hwnd, null, c.FALSE);
            }
            return 0;
        },

        // Right Click: Reset current timer
        c.WM_RBUTTONUP => {
            remaining_seconds = total_seconds;
            is_running = true;
            alert_flash = false;
            _ = c.InvalidateRect(hwnd, null, c.FALSE);
            return 0;
        },

        // Middle Click: Switch between 25m Focus and 5m Break
        c.WM_MBUTTONUP => {
            current_mode = if (current_mode == .focus) .short_break else .focus;
            total_seconds = current_mode.duration();
            remaining_seconds = total_seconds;
            is_running = true;
            alert_flash = false;
            _ = c.InvalidateRect(hwnd, null, c.FALSE);
            return 0;
        },

        c.WM_DESTROY => {
            c.PostQuitMessage(0);
            return 0;
        },

        else => return c.DefWindowProcA(hwnd, msg, wparam, lparam),
    }
}

pub fn main() !void {
    const hInstance = c.GetModuleHandleA(null);
    const class_name = "PerchTimerHUD";

    var wc: c.WNDCLASSEXA = std.mem.zeroes(c.WNDCLASSEXA);
    wc.cbSize = @sizeOf(c.WNDCLASSEXA);
    wc.lpfnWndProc = windowProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = class_name;
    wc.hCursor = c.LoadCursorA(null, c.MAKEINTRESOURCEA(32512));

    if (c.RegisterClassExA(&wc) == 0) return error.ClassFailed;

    const overlay_w: c_int = 160;
    const overlay_h: c_int = 52;
    const margin: c_int = 20;

    const screen_w = c.GetSystemMetrics(c.SM_CXSCREEN);
    const pos_x = screen_w - overlay_w - margin;
    const pos_y = margin;

    // Frameless, topmost, does not show in Alt-Tab menu
    const ex_style = c.WS_EX_TOPMOST | c.WS_EX_TOOLWINDOW;
    const style = c.WS_POPUP;

    const hwnd = c.CreateWindowExA(
        ex_style,
        class_name,
        "Perch",
        style,
        pos_x,
        pos_y,
        overlay_w,
        overlay_h,
        null,
        null,
        hInstance,
        null,
    ) orelse return error.WindowFailed;

    // 500ms timer interval (smooth flashing and exact 1s ticks)
    _ = c.SetTimer(hwnd, 1, 500, null);

    _ = c.ShowWindow(hwnd, c.SW_SHOW);
    _ = c.UpdateWindow(hwnd);

    var msg: c.MSG = undefined;
    while (c.GetMessageA(&msg, null, 0, 0) > 0) {
        _ = c.TranslateMessage(&msg);
        _ = c.DispatchMessageA(&msg);
    }
}
