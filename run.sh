#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
#  waveSync · sound healing infrastructure · v0.1.0
# ═══════════════════════════════════════════════════════════════════════════════

readonly SYNTH_DURATION="${WAVESYNC_DURATION:-1200}"
readonly SYNTH_FREQ_RANGE="${WAVESYNC_FREQ_RANGE:-26-40}"
readonly SYNTH_VOLUME="${WAVESYNC_VOLUME:-0.24}"

# ═══════════════════════════════════════════════════════════════════════════════
#  IRIDESCENT INDIGO PALETTE
# ═══════════════════════════════════════════════════════════════════════════════

readonly C_VOID='\033[38;2;8;8;18m'
readonly C_ABYSS='\033[38;2;15;12;30m'
readonly C_DEEP='\033[38;2;25;20;50m'
readonly C_CORE='\033[38;2;35;28;70m'
readonly C_MID='\033[38;2;45;36;90m'
readonly C_RISE='\033[38;2;55;44;110m'
readonly C_SHIMMER='\033[38;2;65;52;130m'
readonly C_PEARL='\033[38;2;75;60;145m'
readonly C_GLOW='\033[38;2;90;75;160m'
readonly C_ACCENT='\033[38;2;110;90;180m'
readonly C_DIM='\033[2m'
readonly C_RESET='\033[0m'

readonly BOX_TL='╭' BOX_TR='╮' BOX_BL='╰' BOX_BR='╯' BOX_H='─' BOX_V='│' BOX_WAVE='∿'

# ═══════════════════════════════════════════════════════════════════════════════
#  UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

get_width() {
    tput cols 2>/dev/null || echo "${COLUMNS:-80}"
}

strip_ansi() {
    echo -e "$1" | sed $'s/\x1b\\[[0-9;]*m//g'
}

ctr() {
    local text="$1"
    local width
    width=$(get_width)
    local clean
    clean=$(strip_ansi "$text")
    local pad=$(( (width - ${#clean}) / 2 ))
    (( pad < 0 )) && pad=0
    printf "%*s" "$pad" ""
    echo -e "$text"
}

repeat_char() {
    local char="$1"
    local count="$2"
    local result=""
    for ((i=0; i<count; i++)); do
        result+="$char"
    done
    echo "$result"
}

# ═══════════════════════════════════════════════════════════════════════════════
#  SYSTEM DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                if [[ "${ID:-}" =~ ^(raspbian|debian)$ ]] || [[ "${ID_LIKE:-}" == *debian* ]]; then
                    echo "debian"
                else
                    echo "linux"
                fi
            else
                echo "linux"
            fi
            ;;
        *) echo "unix" ;;
    esac
}

check_sox() {
    command -v play &>/dev/null && return
    echo -e "\n${C_ACCENT}[waveSync]${C_RESET} ${C_GLOW}SoX not detected${C_RESET}\n"
    case "$(detect_os)" in
        macos)  echo -e "  ${C_MID}install:${C_RESET} ${C_SHIMMER}brew install sox${C_RESET}" ;;
        *)      echo -e "  ${C_MID}install:${C_RESET} ${C_SHIMMER}sudo apt install sox libsox-fmt-all${C_RESET}" ;;
    esac
    echo ""
    exit 1
}


# ═══════════════════════════════════════════════════════════════════════════════
#  BANNER RENDERING
# ═══════════════════════════════════════════════════════════════════════════════

render_header() {
    local width
    width=$(get_width)
    local banner_width=72
    (( width < banner_width )) && banner_width=$((width - 4))
    
    local wave_line
    wave_line=$(repeat_char "$BOX_WAVE" $((banner_width - 2)))
    local h_line
    h_line=$(repeat_char "$BOX_H" $((banner_width - 2)))
    
    clear
    echo ""
    
    ctr "${C_ABYSS}${BOX_TL}${C_DEEP}${wave_line}${C_ABYSS}${BOX_TR}${C_RESET}"
    ctr "${C_DEEP}${BOX_V}${C_RESET}$(printf "%*s" $((banner_width-2)) "")${C_DEEP}${BOX_V}${C_RESET}"
    
    ctr "${C_DEEP}${BOX_V}${C_RESET}      ${C_ABYSS}██╗    ██╗${C_DEEP}  ██████╗${C_RESET}      ${C_DEEP}${BOX_V}${C_RESET}"
    ctr "${C_DEEP}${BOX_V}${C_RESET}      ${C_DEEP}██║    ██║${C_CORE} ██╔════╝${C_RESET}      ${C_DEEP}${BOX_V}${C_RESET}"
    ctr "${C_DEEP}${BOX_V}${C_RESET}      ${C_CORE}██║ █╗ ██║${C_MID} ╚█████╗${C_RESET}       ${C_DEEP}${BOX_V}${C_RESET}"
    ctr "${C_DEEP}${BOX_V}${C_RESET}      ${C_MID}██║███╗██║${C_RISE}  ╚═══██╗${C_RESET}      ${C_DEEP}${BOX_V}${C_RESET}"
    ctr "${C_DEEP}${BOX_V}${C_RESET}      ${C_RISE}╚███╔███╔╝${C_SHIMMER} ██████╔╝${C_RESET}      ${C_DEEP}${BOX_V}${C_RESET}"
    ctr "${C_DEEP}${BOX_V}${C_RESET}      ${C_SHIMMER} ╚══╝╚══╝${C_PEARL}  ╚═════╝${C_RESET}       ${C_DEEP}${BOX_V}${C_RESET}"
    
    ctr "${C_DEEP}${BOX_V}${C_RESET}$(printf "%*s" $((banner_width-2)) "")${C_DEEP}${BOX_V}${C_RESET}"
    ctr "${C_CORE}${BOX_V}${C_DIM}${C_DEEP}${h_line}${C_RESET}${C_CORE}${BOX_V}${C_RESET}"
    ctr "${C_DEEP}${BOX_V}${C_RESET}$(printf "%*s" $((banner_width-2)) "")${C_DEEP}${BOX_V}${C_RESET}"
    
    ctr "${C_DEEP}${BOX_V}${C_RESET}          ${C_MID}◈  ${C_RISE}s o u n d   h e a l i n g${C_MID}  ◈${C_RESET}          ${C_DEEP}${BOX_V}${C_RESET}"
    
    ctr "${C_DEEP}${BOX_V}${C_RESET}$(printf "%*s" $((banner_width-2)) "")${C_DEEP}${BOX_V}${C_RESET}"
    ctr "${C_ABYSS}${BOX_BL}${C_DEEP}${wave_line}${C_ABYSS}${BOX_BR}${C_RESET}"
    echo ""
}

render_info() {

    
    local synth_info="${C_DEEP}sine${C_RESET} ${C_MID}◈${C_RESET} ${C_SHIMMER}${SYNTH_FREQ_RANGE}Hz${C_RESET}  "
    synth_info+="${C_DEEP}duration${C_RESET} ${C_MID}◈${C_RESET} ${C_SHIMMER}${SYNTH_DURATION}s${C_RESET}  "
    synth_info+="${C_DEEP}vol${C_RESET} ${C_MID}◈${C_RESET} ${C_SHIMMER}${SYNTH_VOLUME}${C_RESET}"
    ctr "$synth_info"
    echo ""
    
    ctr "${C_CORE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    echo ""
}

render_timestamp() {
    local label="$1"
    local timestamp="$2"
    ctr "${C_DEEP}${label}${C_RESET} ${C_MID}◈${C_RESET} ${C_SHIMMER}${timestamp}${C_RESET}"
}

render_status() {
    local message="$1"
    local color="${2:-$C_SHIMMER}"
    ctr "${C_MID}[${C_RESET}${color}${message}${C_RESET}${C_MID}]${C_RESET}"
}

run_synth_custom() {
    play -n synth "$1" sine "$2" vol "$3"
}

run_synth_focus(){
    play -n synth "$1" sine 35 tremolo 8 vol 0.24
}




# ═══════════════════════════════════════════════════════════════════════════════
#  SIGNAL HANDLING
# ═══════════════════════════════════════════════════════════════════════════════

cleanup() {
    END_TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S %Z")
    echo ""
    render_timestamp "session end  " "$END_TIMESTAMP"
    echo ""
    render_status "terminated" "$C_ACCENT"
    echo ""
    exit 0
}

trap cleanup INT TERM

# ═══════════════════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    check_sox
    
    render_header
    render_info
    
    START_TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S %Z")
    render_timestamp "session start" "$START_TIMESTAMP"
    echo ""
    
    render_status "synthesizing" "$C_PEARL"
    echo ""
    
    run_synth_focus "$SYNTH_DURATION"
    #run_synth "$SYNTH_DURATION" "$SYNTH_FREQ_RANGE" "$SYNTH_VOLUME"
    
    END_TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S %Z")
    render_timestamp "session end  " "$END_TIMESTAMP"
    echo ""
    
    render_status "complete" "$C_GLOW"
    echo ""
}

main "$@"