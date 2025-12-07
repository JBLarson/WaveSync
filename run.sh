#!/usr/bin/env bash
#
# �═══════════════════════════════════════════════════════════════════════════════
#  waveSync · sound healing infrastructure · v0.1.0
#  ───────────────────────────────────────────────────────────────────────────────
#  cross-platform frequency synthesis for Unix systems
#  requires: SoX (Sound eXchange) · brew install sox | apt install sox
# �═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
#  CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

readonly SYNTH_DURATION="${WAVESYNC_DURATION:-60}"
readonly SYNTH_FREQ_START="${WAVESYNC_FREQ_START:-0}"
readonly SYNTH_FREQ_END="${WAVESYNC_FREQ_END:-42}"
readonly SYNTH_VOLUME="${WAVESYNC_VOLUME:-0.28}"
readonly SYNTH_WAVEFORM="${WAVESYNC_WAVEFORM:-sine}"

# ═══════════════════════════════════════════════════════════════════════════════
#  IRIDESCENT INDIGO PALETTE · DARK MODE NATIVE
# ═══════════════════════════════════════════════════════════════════════════════
#  designed for #000000 backgrounds, tolerant of #FFFFFF
#  pearlescent depth through strategic luminance gradients

readonly C_VOID='\033[38;2;8;8;18m'        # near-black base
readonly C_ABYSS='\033[38;2;15;12;30m'     # deepest indigo
readonly C_DEEP='\033[38;2;25;20;50m'      # deep indigo
readonly C_CORE='\033[38;2;35;28;70m'      # core indigo
readonly C_MID='\033[38;2;45;36;90m'       # mid indigo
readonly C_RISE='\033[38;2;55;44;110m'     # rising indigo
readonly C_SHIMMER='\033[38;2;65;52;130m'  # shimmer point
readonly C_PEARL='\033[38;2;75;60;145m'    # pearlescent edge
readonly C_GLOW='\033[38;2;90;75;160m'     # subtle glow
readonly C_ACCENT='\033[38;2;110;90;180m'  # accent highlights

readonly C_DIM='\033[2m'
readonly C_BOLD='\033[1m'
readonly C_RESET='\033[0m'

# box drawing with iridescent gradient
readonly BOX_TL='╭'
readonly BOX_TR='╮'
readonly BOX_BL='╰'
readonly BOX_BR='╯'
readonly BOX_H='─'
readonly BOX_V='│'
readonly BOX_WAVE='∿'

# ═══════════════════════════════════════════════════════════════════════════════
#  UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

get_terminal_width() {
    local width
    if command -v tput &>/dev/null; then
        width=$(tput cols 2>/dev/null) || width=80
    elif [[ -n "${COLUMNS:-}" ]]; then
        width=$COLUMNS
    else
        width=80
    fi
    echo "$width"
}

center_text() {
    local text="$1"
    local width="$2"
    local text_length=${#text}
    local padding=$(( (width - text_length) / 2 ))
    [[ $padding -lt 0 ]] && padding=0
    printf "%*s%s" "$padding" "" "$text"
}

strip_ansi() {
    echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

center_colored_text() {
    local colored_text="$1"
    local width="$2"
    local stripped
    stripped=$(strip_ansi "$colored_text")
    local text_length=${#stripped}
    local padding=$(( (width - text_length) / 2 ))
    [[ $padding -lt 0 ]] && padding=0
    printf "%*s" "$padding" ""
    echo -e "$colored_text"
}

format_timestamp() {
    local label="$1"
    local timestamp="$2"
    echo -e "${C_DEEP}${label}${C_RESET} ${C_MID}◈${C_RESET} ${C_SHIMMER}${timestamp}${C_RESET}"
}

# ═══════════════════════════════════════════════════════════════════════════════
#  SYSTEM DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

detect_os() {
    case "$(uname -s)" in
        Darwin*)  echo "macos" ;;
        Linux*)   
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                if [[ "${ID:-}" == "raspbian" ]] || [[ "${ID:-}" == "debian" ]] || [[ "${ID_LIKE:-}" == *"debian"* ]]; then
                    echo "debian"
                else
                    echo "linux"
                fi
            else
                echo "linux"
            fi
            ;;
        *)        echo "unix" ;;
    esac
}

check_sox_installed() {
    if ! command -v play &>/dev/null; then
        local os
        os=$(detect_os)
        echo -e "${C_ACCENT}[waveSync]${C_RESET} ${C_GLOW}SoX not detected${C_RESET}"
        echo ""
        case "$os" in
            macos)
                echo -e "  ${C_MID}install via:${C_RESET} ${C_SHIMMER}brew install sox${C_RESET}"
                ;;
            debian|linux)
                echo -e "  ${C_MID}install via:${C_RESET} ${C_SHIMMER}sudo apt install sox libsox-fmt-all${C_RESET}"
                ;;
            *)
                echo -e "  ${C_MID}install SoX from:${C_RESET} ${C_SHIMMER}https://sox.sourceforge.net${C_RESET}"
                ;;
        esac
        echo ""
        exit 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
#  AUDIO SYSTEM INTROSPECTION
# ═══════════════════════════════════════════════════════════════════════════════

get_audio_info_macos() {
    local info=""
    
    # primary output device
    if command -v system_profiler &>/dev/null; then
        local audio_data
        audio_data=$(system_profiler SPAudioDataType 2>/dev/null || echo "")
        
        if [[ -n "$audio_data" ]]; then
            local device_name
            device_name=$(echo "$audio_data" | grep -A5 "Output:" | grep "Default Output Device: Yes" -B5 2>/dev/null | head -1 | sed 's/^[[:space:]]*//' | sed 's/:$//' || echo "")
            
            if [[ -z "$device_name" ]]; then
                device_name=$(echo "$audio_data" | grep -E "^\s{8}[A-Za-z]" | head -1 | sed 's/^[[:space:]]*//' | sed 's/:$//' || echo "Unknown")
            fi
            
            info+="${C_DEEP}output${C_RESET} ${C_MID}◈${C_RESET} ${C_SHIMMER}${device_name}${C_RESET}"
        fi
    fi
    
    # coreaudio sample rate
    if command -v defaults &>/dev/null; then
        local sample_rate
        sample_rate=$(defaults read com.apple.audio.SystemSettings 2>/dev/null | grep -i "sampleRate" | head -1 | grep -oE '[0-9]+' || echo "")
        if [[ -n "$sample_rate" ]]; then
            [[ -n "$info" ]] && info+="  "
            info+="${C_DEEP}rate${C_RESET} ${C_MID}◈${C_RESET} ${C_SHIMMER}${sample_rate}Hz${C_RESET}"
        fi
    fi
    
    # check for external DAC via ioreg
    if command -v ioreg &>/dev/null; then
        local usb_audio
        usb_audio=$(ioreg -c IOUSBHostDevice -r 2>/dev/null | grep -i "audio\|dac\|usb.*audio" | head -1 || echo "")
        if [[ -n "$usb_audio" ]]; then
            [[ -n "$info" ]] && info+="  "
            info+="${C_DEEP}interface${C_RESET} ${C_MID}◈${C_RESET} ${C_SHIMMER}USB Audio${C_RESET}"
        fi
    fi
    
    echo -e "$info"
}

get_audio_info_linux() {
    local info=""
    
    # ALSA default device
    if command -v aplay &>/dev/null; then
        local default_card
        default_card=$(aplay -l 2>/dev/null | grep -E "^card [0-9]" | head -1 | sed 's/card [0-9]: //' | cut -d',' -f1 || echo "")
        if [[ -n "$default_card" ]]; then
            info+="${C_DEEP}device${C_RESET} ${C_MID}◈${C_RESET} ${C_SHIMMER}${default_card}${C_RESET}"
        fi
    fi
    
    # PulseAudio/PipeWire sink
    if command -v pactl &>/dev/null; then
        local sink
        sink=$(pactl get-default-sink 2>/dev/null || echo "")
        if [[ -n "$sink" ]] && [[ "$sink" != "null" ]]; then
            local sink_name
            sink_name=$(pactl list sinks 2>/dev/null | grep -A1 "Name: $sink" | grep "Description:" | sed 's/.*Description: //' | head -1 || echo "$sink")
            [[ -n "$info" ]] && info+="  "
            info+="${C_DEEP}sink${C_RESET} ${C_MID}◈${C_RESET} ${C_SHIMMER}${sink_name}${C_RESET}"
        fi
    fi
    
    # sample rate from ALSA
    if [[ -f /proc/asound/card0/pcm0p/sub0/hw_params ]]; then
        local rate
        rate=$(grep "rate:" /proc/asound/card0/pcm0p/sub0/hw_params 2>/dev/null | awk '{print $2}' || echo "")
        if [[ -n "$rate" ]]; then
            [[ -n "$info" ]] && info+="  "
            info+="${C_DEEP}rate${C_RESET} ${C_MID}◈${C_RESET} ${C_SHIMMER}${rate}Hz${C_RESET}"
        fi
    fi
    
    echo -e "$info"
}

get_audio_info() {
    local os
    os=$(detect_os)
    case "$os" in
        macos)  get_audio_info_macos ;;
        *)      get_audio_info_linux ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
#  BANNER RENDERING
# ═══════════════════════════════════════════════════════════════════════════════

render_banner() {
    local width
    width=$(get_terminal_width)
    local start_ts="$1"
    local end_ts="${2:-}"
    local audio_info
    audio_info=$(get_audio_info)
    
    # constrain banner width
    local banner_width=74
    [[ $width -lt $banner_width ]] && banner_width=$((width - 4))
    
    local pad=$(( (width - banner_width) / 2 ))
    [[ $pad -lt 0 ]] && pad=0
    local indent
    indent=$(printf "%*s" "$pad" "")
    
    # wave border generator
    local wave_line=""
    for ((i=0; i<banner_width-2; i++)); do
        wave_line+="${BOX_WAVE}"
    done
    
    local h_line=""
    for ((i=0; i<banner_width-2; i++)); do
        h_line+="${BOX_H}"
    done
    
    clear
    echo ""
    
    # top border with gradient
    echo -e "${indent}${C_ABYSS}${BOX_TL}${C_DEEP}${wave_line}${C_ABYSS}${BOX_TR}${C_RESET}"
    echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}$(printf "%*s" "$((banner_width-2))" "")${C_DEEP}${BOX_V}${C_RESET}"
    
    # ASCII art with deep iridescent gradient
    echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}  ${C_ABYSS}██╗    ██╗${C_DEEP} █████╗ ${C_CORE}██╗   ██╗${C_MID}███████╗${C_RISE}███████╗${C_SHIMMER}██╗   ██╗${C_PEARL}███╗   ██╗${C_GLOW} ██████╗${C_RESET}  ${C_DEEP}${BOX_V}${C_RESET}"
    echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}  ${C_ABYSS}██║    ██║${C_DEEP}██╔══██╗${C_CORE}██║   ██║${C_MID}██╔════╝${C_RISE}██╔════╝${C_SHIMMER}╚██╗ ██╔╝${C_PEARL}████╗  ██║${C_GLOW}██╔════╝${C_RESET}  ${C_DEEP}${BOX_V}${C_RESET}"
    echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}  ${C_DEEP}██║ █╗ ██║${C_CORE}███████║${C_MID}██║   ██║${C_RISE}█████╗  ${C_SHIMMER}███████╗${C_PEARL} ╚████╔╝ ${C_GLOW}██╔██╗ ██║${C_ACCENT}██║     ${C_RESET}  ${C_DEEP}${BOX_V}${C_RESET}"
    echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}  ${C_CORE}██║███╗██║${C_MID}██╔══██║${C_RISE}╚██╗ ██╔╝${C_SHIMMER}██╔══╝  ${C_PEARL}╚════██║${C_GLOW}  ╚██╔╝  ${C_ACCENT}██║╚██╗██║${C_GLOW}██║     ${C_RESET}  ${C_DEEP}${BOX_V}${C_RESET}"
    echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}  ${C_MID}╚███╔███╔╝${C_RISE}██║  ██║${C_SHIMMER} ╚████╔╝ ${C_PEARL}███████╗${C_GLOW}███████║${C_ACCENT}   ██║   ${C_GLOW}██║ ╚████║${C_SHIMMER}╚██████╗${C_RESET}  ${C_DEEP}${BOX_V}${C_RESET}"
    echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}  ${C_RISE} ╚══╝╚══╝ ${C_SHIMMER}╚═╝  ╚═╝${C_PEARL}  ╚═══╝  ${C_GLOW}╚══════╝${C_ACCENT}╚══════╝${C_GLOW}   ╚═╝   ${C_SHIMMER}╚═╝  ╚═══╝${C_PEARL} ╚═════╝${C_RESET}  ${C_DEEP}${BOX_V}${C_RESET}"
    
    echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}$(printf "%*s" "$((banner_width-2))" "")${C_DEEP}${BOX_V}${C_RESET}"
    
    # divider
    echo -e "${indent}${C_CORE}${BOX_V}${C_DIM}${C_DEEP}${h_line}${C_RESET}${C_CORE}${BOX_V}${C_RESET}"
    
    echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}$(printf "%*s" "$((banner_width-2))" "")${C_DEEP}${BOX_V}${C_RESET}"
    
    # tagline
    local tagline="◈  s o u n d   h e a l i n g   i n f r a s t r u c t u r e  ◈"
    local tagline_pad=$(( (banner_width - 2 - ${#tagline}) / 2 ))
    echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}$(printf "%*s" "$tagline_pad" "")${C_MID}${tagline}${C_RESET}$(printf "%*s" "$((banner_width - 2 - tagline_pad - ${#tagline}))" "")${C_DEEP}${BOX_V}${C_RESET}"
    
    echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}$(printf "%*s" "$((banner_width-2))" "")${C_DEEP}${BOX_V}${C_RESET}"
    
    # session info divider
    echo -e "${indent}${C_CORE}${BOX_V}${C_DIM}${C_DEEP}${h_line}${C_RESET}${C_CORE}${BOX_V}${C_RESET}"
    
    echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}$(printf "%*s" "$((banner_width-2))" "")${C_DEEP}${BOX_V}${C_RESET}"
    
    # timestamps
    local ts_start_label="session start"
    local ts_start_formatted
    ts_start_formatted=$(format_timestamp "$ts_start_label" "$start_ts")
    local ts_start_stripped
    ts_start_stripped=$(strip_ansi "$ts_start_formatted")
    local ts_start_pad=$(( (banner_width - 2 - ${#ts_start_stripped}) / 2 ))
    echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}$(printf "%*s" "$ts_start_pad" "")${ts_start_formatted}$(printf "%*s" "$((banner_width - 2 - ts_start_pad - ${#ts_start_stripped}))" "")${C_DEEP}${BOX_V}${C_RESET}"
    
    if [[ -n "$end_ts" ]]; then
        local ts_end_label="session end  "
        local ts_end_formatted
        ts_end_formatted=$(format_timestamp "$ts_end_label" "$end_ts")
        local ts_end_stripped
        ts_end_stripped=$(strip_ansi "$ts_end_formatted")
        local ts_end_pad=$(( (banner_width - 2 - ${#ts_end_stripped}) / 2 ))
        echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}$(printf "%*s" "$ts_end_pad" "")${ts_end_formatted}$(printf "%*s" "$((banner_width - 2 - ts_end_pad - ${#ts_end_stripped}))" "")${C_DEEP}${BOX_V}${C_RESET}"
    fi
    
    echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}$(printf "%*s" "$((banner_width-2))" "")${C_DEEP}${BOX_V}${C_RESET}"
    
    # audio system info
    if [[ -n "$audio_info" ]]; then
        echo -e "${indent}${C_CORE}${BOX_V}${C_DIM}${C_DEEP}${h_line}${C_RESET}${C_CORE}${BOX_V}${C_RESET}"
        echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}$(printf "%*s" "$((banner_width-2))" "")${C_DEEP}${BOX_V}${C_RESET}"
        
        local audio_stripped
        audio_stripped=$(strip_ansi "$audio_info")
        local audio_pad=$(( (banner_width - 2 - ${#audio_stripped}) / 2 ))
        echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}$(printf "%*s" "$audio_pad" "")${audio_info}$(printf "%*s" "$((banner_width - 2 - audio_pad - ${#audio_stripped}))" "")${C_DEEP}${BOX_V}${C_RESET}"
        
        echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}$(printf "%*s" "$((banner_width-2))" "")${C_DEEP}${BOX_V}${C_RESET}"
    fi
    
    # synthesis parameters
    echo -e "${indent}${C_CORE}${BOX_V}${C_DIM}${C_DEEP}${h_line}${C_RESET}${C_CORE}${BOX_V}${C_RESET}"
    echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}$(printf "%*s" "$((banner_width-2))" "")${C_DEEP}${BOX_V}${C_RESET}"
    
    local synth_info="${C_DEEP}waveform${C_RESET} ${C_MID}◈${C_RESET} ${C_SHIMMER}${SYNTH_WAVEFORM}${C_RESET}  ${C_DEEP}sweep${C_RESET} ${C_MID}◈${C_RESET} ${C_SHIMMER}${SYNTH_FREQ_START}→${SYNTH_FREQ_END}Hz${C_RESET}  ${C_DEEP}duration${C_RESET} ${C_MID}◈${C_RESET} ${C_SHIMMER}${SYNTH_DURATION}s${C_RESET}  ${C_DEEP}vol${C_RESET} ${C_MID}◈${C_RESET} ${C_SHIMMER}${SYNTH_VOLUME}${C_RESET}"
    local synth_stripped
    synth_stripped=$(strip_ansi "$synth_info")
    local synth_pad=$(( (banner_width - 2 - ${#synth_stripped}) / 2 ))
    echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}$(printf "%*s" "$synth_pad" "")${synth_info}$(printf "%*s" "$((banner_width - 2 - synth_pad - ${#synth_stripped}))" "")${C_DEEP}${BOX_V}${C_RESET}"
    
    echo -e "${indent}${C_DEEP}${BOX_V}${C_RESET}$(printf "%*s" "$((banner_width-2))" "")${C_DEEP}${BOX_V}${C_RESET}"
    
    # bottom border
    echo -e "${indent}${C_ABYSS}${BOX_BL}${C_DEEP}${wave_line}${C_ABYSS}${BOX_BR}${C_RESET}"
    echo ""
}

render_status() {
    local width
    width=$(get_terminal_width)
    local message="$1"
    local color="${2:-$C_SHIMMER}"
    
    local status_text="${C_MID}[${C_RESET}${color}${message}${C_RESET}${C_MID}]${C_RESET}"
    center_colored_text "$status_text" "$width"
}

# ═══════════════════════════════════════════════════════════════════════════════
#  SIGNAL HANDLING
# ═══════════════════════════════════════════════════════════════════════════════

cleanup() {
    local end_timestamp
    end_timestamp=$(date "+%Y-%m-%d %H:%M:%S %Z")
    echo ""
    render_banner "$START_TIMESTAMP" "$end_timestamp"
    render_status "session terminated" "$C_ACCENT"
    echo ""
    exit 0
}

trap cleanup SIGINT SIGTERM

# ═══════════════════════════════════════════════════════════════════════════════
#  MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    check_sox_installed
    
    START_TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S %Z")
    
    render_banner "$START_TIMESTAMP"
    render_status "initializing frequency synthesis" "$C_SHIMMER"
    echo ""
    sleep 1
    
    render_banner "$START_TIMESTAMP"
    render_status "synthesizing ${SYNTH_FREQ_START}→${SYNTH_FREQ_END}Hz sweep" "$C_PEARL"
    echo ""
    
    # execute synthesis
    play -q -n synth "$SYNTH_DURATION" "$SYNTH_WAVEFORM" "${SYNTH_FREQ_START}-${SYNTH_FREQ_END}" vol "$SYNTH_VOLUME" 2>/dev/null || {
        render_status "synthesis engine error" "$C_ACCENT"
        exit 1
    }
    
    local end_timestamp
    end_timestamp=$(date "+%Y-%m-%d %H:%M:%S %Z")
    
    render_banner "$START_TIMESTAMP" "$end_timestamp"
    render_status "synthesis complete" "$C_GLOW"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
#  ENTRY POINT
# ═══════════════════════════════════════════════════════════════════════════════

main "$@"