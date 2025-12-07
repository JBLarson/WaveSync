#!/usr/bin/env bash
set -euo pipefail

SYNTH_DURATION="${WAVESYNC_DURATION:-60}"
SYNTH_FREQ_RANGE="${WAVESYNC_FREQ_RANGE:-0-42}"
SYNTH_VOLUME="${WAVESYNC_VOLUME:-0.28}"

C0='\033[38;2;4;2;10m'
C1='\033[38;2;8;5;18m'
C2='\033[38;2;14;9;30m'
C3='\033[38;2;22;15;46m'
C4='\033[38;2;32;22;64m'
C5='\033[38;2;44;32;86m'
C6='\033[38;2;58;44;110m'
C7='\033[38;2;74;58;134m'
C8='\033[38;2;92;74;158m'
C9='\033[38;2;112;92;184m'
R='\033[0m'

get_width() { tput cols 2>/dev/null || echo 80; }

check_sox() {
    command -v play &>/dev/null && return
    echo -e "\n${C7}[waveSync]${R} ${C5}SoX required${R}"
    [[ "$(uname -s)" == Darwin* ]] && echo -e "  ${C4}brew install sox${R}" || echo -e "  ${C4}sudo apt install sox libsox-fmt-all${R}"
    exit 1
}

get_audio() {
    case "$(uname -s)" in
        Darwin*) system_profiler SPAudioDataType 2>/dev/null | grep -E "^\s+[A-Za-z].*:$" | head -1 | sed 's/^[[:space:]]*//;s/:$//' || true ;;
        *) aplay -l 2>/dev/null | grep -E "^card" | head -1 | sed 's/card [0-9]: //;s/,.*//' || true ;;
    esac
}

strip_ansi() { echo -e "$1" | sed $'s/\x1b\\[[0-9;]*m//g'; }

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

render() {
    local start_ts="$1"
    local end_ts="${2:-}"
    local audio
    audio=$(get_audio)
    
    clear
    echo ""
    echo ""
    
    ctr "${C1}██╗    ██╗${C2}  ██████╗${R}"
    ctr "${C2}██║    ██║${C3} ██╔════╝${R}"
    ctr "${C3}██║ █╗ ██║${C4} ╚█████╗${R}"
    ctr "${C4}██║███╗██║${C5}  ╚═══██╗${R}"
    ctr "${C5}╚███╔███╔╝${C6} ██████╔╝${R}"
    ctr "${C6} ╚══╝╚══╝${C7}  ╚═════╝${R}"
    
    echo ""
    ctr "${C4}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
    echo ""
    ctr "${C5}w ${C6}a ${C5}v ${C6}e ${C7}S ${C8}y ${C7}n ${C8}c${R}"
    echo ""
    ctr "${C6}◈  ${C5}s o u n d   h e a l i n g   i n f r a s t r u c t u r e${R}  ${C6}◈${R}"
    echo ""
    ctr "${C4}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
    echo ""
    
    ctr "${C4}start${R}  ${C6}·${R}  ${C8}${start_ts}${R}"
    [[ -n "$end_ts" ]] && ctr "${C4}end  ${R}  ${C6}·${R}  ${C8}${end_ts}${R}"
    echo ""
    
    [[ -n "$audio" ]] && { ctr "${C4}out${R} ${C6}·${R} ${C8}${audio}${R}"; echo ""; }
    
    ctr "${C4}sine${R} ${C6}·${R} ${C8}${SYNTH_FREQ_RANGE}Hz${R}   ${C4}dur${R} ${C6}·${R} ${C8}${SYNTH_DURATION}s${R}   ${C4}vol${R} ${C6}·${R} ${C8}${SYNTH_VOLUME}${R}"
    echo ""
}

status() { ctr "${C6}[ ${C8}$1${C6} ]${R}"; }

cleanup() {
    END_TS=$(date '+%Y-%m-%d %H:%M:%S %Z')
    echo ""
    render "$START_TS" "$END_TS"
    status "terminated"
    echo ""
    exit 0
}

trap cleanup INT TERM

main() {
    check_sox
    START_TS=$(date '+%Y-%m-%d %H:%M:%S %Z')
    render "$START_TS"
    status "initializing"
    sleep 1
    render "$START_TS"
    status "synthesizing ${SYNTH_FREQ_RANGE}Hz"
    echo ""
    
    play -n synth 60 sine 20-28 vol 0.42

    # repeatedly failing Claude attempt
    #play -n synth "$SYNTH_DURATION" sine "$SYNTH_FREQ_RANGE" vol "$SYNTH_VOLUME"
    
    END_TS=$(date '+%Y-%m-%d %H:%M:%S %Z')
    render "$START_TS" "$END_TS"
    status "complete"
    echo ""
}

main "$@"