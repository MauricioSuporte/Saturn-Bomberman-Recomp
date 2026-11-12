/* launcher.c -- SaturnBomberman.exe, the per-title entry point.
 *
 * Sits in the repository root and starts SaturnRecomp's shared runtime with
 * the local game declaration. It holds no game code or data: the runtime reads
 * the user's own BIOS and disc named in game\game.toml.
 */
#include <windows.h>
#include <wchar.h>

#define N 32768

static int missing(const wchar_t *path)
{
    return GetFileAttributesW(path) == INVALID_FILE_ATTRIBUTES;
}

static int fail(const wchar_t *text)
{
    MessageBoxW(NULL, text, L"Saturn Bomberman", MB_ICONERROR);
    return 1;
}

int WINAPI wWinMain(HINSTANCE inst, HINSTANCE prev, PWSTR args, int show)
{
    static wchar_t root[N], runtime[N], game[N], toml[N], settings[N], cmd[N], log_path[N];
    SECURITY_ATTRIBUTES sa = { sizeof sa, NULL, TRUE };
    STARTUPINFOW si;
    PROCESS_INFORMATION pi;
    HANDLE log, input;
    DWORD code = 1;
    wchar_t *slash;
    BOOL ok;

    (void)inst; (void)prev; (void)show;

    if (!GetModuleFileNameW(NULL, root, N)) return 1;
    slash = wcsrchr(root, L'\\');
    if (!slash) return 1;
    *slash = 0;

    swprintf(runtime,  N, L"%ls\\external\\SaturnRecomp\\runner\\saturnwin.exe", root);
    swprintf(game,     N, L"%ls\\game", root);
    swprintf(toml,     N, L"%ls\\game\\game.toml", root);
    swprintf(settings, N, L"%ls\\game\\settings.ini", root);
    swprintf(log_path, N, L"%ls\\game\\runtime.log", root);

    if (missing(runtime))
        return fail(L"The runtime has not been built yet.\nRun setup.ps1 first.");
    if (missing(toml))
        return fail(L"game\\game.toml is missing.\nRun setup.ps1 first.");

    /* Presentation settings (F1 panel) live beside the game declaration. */
    SetEnvironmentVariableW(L"SATURN_SETTINGS_FILE", settings);
    if (!SetCurrentDirectoryW(game)) return 1;

    if (args && *args) swprintf(cmd, N, L"\"%ls\" game.toml %ls", runtime, args);
    else               swprintf(cmd, N, L"\"%ls\" game.toml", runtime);

    log   = CreateFileW(log_path, GENERIC_WRITE, FILE_SHARE_READ, &sa, CREATE_ALWAYS,
                        FILE_ATTRIBUTE_NORMAL, NULL);
    input = CreateFileW(L"NUL", GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, &sa,
                        OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    ZeroMemory(&si, sizeof si);
    ZeroMemory(&pi, sizeof pi);
    si.cb = sizeof si;
    if (log != INVALID_HANDLE_VALUE && input != INVALID_HANDLE_VALUE) {
        si.dwFlags    = STARTF_USESTDHANDLES;
        si.hStdOutput = log;
        si.hStdError  = log;
        si.hStdInput  = input;
    }
    ok = CreateProcessW(runtime, cmd, NULL, NULL, TRUE, CREATE_NO_WINDOW, NULL, game, &si, &pi);
    if (log != INVALID_HANDLE_VALUE)   CloseHandle(log);
    if (input != INVALID_HANDLE_VALUE) CloseHandle(input);
    if (!ok)
        return fail(L"The runtime could not be started.\nRun setup.ps1 again.");

    CloseHandle(pi.hThread);
    WaitForSingleObject(pi.hProcess, INFINITE);
    GetExitCodeProcess(pi.hProcess, &code);
    CloseHandle(pi.hProcess);
    if (code)
        fail(L"The game stopped with an error.\nSee game\\runtime.log for details.");
    return (int)code;
}
