#!/bin/bash
# set -x
PLANSZA=("")
KONIEC="0"
DIM=2
let TRUE_DIM=$DIM+1
AUTO='false'
GRACZ=0
ERROR=0
MSG_0="Twój Ruch"
MSG=$MSG_0
ALPHABET="A B C D E F G H I J K L M N O P Q R S T U W X Y Z "
MAX_DIM=26
MIN_DIM=3
WYGRANA=255
MAX_RUCHOW=9
RUCH=0
PUSTE="."

##
# \brief Ustawia tryb verbose
##
function set_vervose {
    set -x
}

##
# \brief Wyswitla stan planszy
##
function wyswietl {
    clear
    let ZAKRES=TRUE_DIM*2
    echo "#  ${ALPHABET:0:$ZAKRES}"

    for i in $(eval echo "{0..$DIM}")
    do
        PLANSZA_TMP=""
        for j in $(eval echo "{0..$DIM}")
        do
            let ch=$i*$TRUE_DIM+$j
            PLANSZA_TMP="$PLANSZA_TMP ${PLANSZA[ch]}"
        done
        echo "$i $PLANSZA_TMP"
    done

}

##
# \brief Sprawdza czy podanee 3 argumenty nie są pustę i czy sta takie same
# \param $1 Argument do porównania
# \param $2 Argument do porównania
# \param $3 Argument do porównania
# \return 1 gdy argument są niepuste i takie same.
##
function takie_same {
    if [[ "$1" != "${PUSTE}" ]] && [[ "$2" != "${PUSTE}" ]] && [[ "$3" != "${PUSTE}" ]]; then 
        if [[ "$1" = "$2" ]] && [[ "$2" = "$3" ]]; then
            return 1
        fi
    fi

    return 0
}

##
# \brief Spawrdza czy warunek zachodzi na macierzy 3 na 3 z podanym offsetem dla danego gracza
# \param $1 Symbol jakim operuje gracz
# \param $2 offest w poziomie
# \param $3 offset w pionie
# \return 1 gdy gdzies w maicerzy zachoidzi warunek wygranej.
##
function sprawdz_wygrana_3_3 {
    SYMBOL=$1
    i=$2
    j=$3
    for x in {0..2}
    do
        # Czy w wierszu ?
        let ix=i+x
        let ch1=$ix*$TRUE_DIM+$j
        let ch2=$ix*$TRUE_DIM+$j+1
        let ch3=$ix*$TRUE_DIM+$j+2
        takie_same "${PLANSZA[ch1]}" "${PLANSZA[ch2]}" "${PLANSZA[ch3]}"
        local res=$?
        if [ 1 -eq $res ]; then
            return 1
        fi
    done

    for x in {0..2}
    do
        # Czy w kolumnie ?
        let jx=j+x
        let ch1=$i*$TRUE_DIM+$jx
        let ch2=$(expr $i+1)*$TRUE_DIM+$jx
        let ch3=$(expr $i+2)*$TRUE_DIM+$jx
        takie_same ${PLANSZA[ch1]} ${PLANSZA[ch2]} ${PLANSZA[ch3]}
        local res=$?
        if [ 1 -eq $res ]; then
            return 1
        fi
    done

    let ch1=$i*$TRUE_DIM+$j
    let ch2=$(expr $i+1)*$TRUE_DIM+$j+1
    let ch3=$(expr $i+2)*$TRUE_DIM+$j+2
    takie_same ${PLANSZA[ch1]} ${PLANSZA[ch2]} ${PLANSZA[ch3]}
    local res=$?
    if [ 1 -eq $res ]; then
        return 1
    fi

    let ch1=$i*$TRUE_DIM+$j+2
    let ch2=$(expr $i+1)*$TRUE_DIM+$j+1
    let ch3=$(expr $i+2)*$TRUE_DIM+$j
    takie_same ${PLANSZA[ch1]} ${PLANSZA[ch2]} ${PLANSZA[ch3]}
    local res=$?
    if [ 1 -eq $res ]; then
        return 1
    fi

    return 0
}

##
# \brief Dla wszytskich możliwych sub-macierzy o rozmiarze 3 na 3 spawrdza czy zachodzi watunek wygranej
# \param $1 Symbol jakim operuje gracz
# \return 1 gdy gdzies w maicerzy zachoidzi warunek wygranej.
##
function sprawdz_wygrana {
    let TMP_DIM=TRUE_DIM-MIN_DIM
    for i in $(eval echo "{0..$TMP_DIM}")
    do
        for j in $(eval echo "{0..$TMP_DIM}")
        do
            sprawdz_wygrana_3_3 $1 $i $j
            local res=$?
            if [ 1 -eq $res ]; then
                return 1
            fi
            set +x
        done
    done

    return 0
}

##
# \brief Podmienia ID aktywnego gracza
##
function zmiana_gracza {
    let GRACZ++
    let GRACZ=GRACZ%2
}

##
# \brief Weryfikuje zarządanee przez użytkownika zmiane rozmiaru planszy
##
function eval_plansza {
    echo $1
    if [ ! -z $1 ]; then
        TRUE_DIM=$1
        if [ $TRUE_DIM -gt $MAX_DIM ]; then
            TRUE_DIM=$MAX_DIM
        fi
        let DIM=${TRUE_DIM}-1
    fi
    set +x
}

##
# \brief Inicjalizuje rozgrywke
##
function zacznij {
    while getopts 'd:avh' flag; do
        case "${flag}" in
            a) AUTO='true' ;;
            d) eval_plansza ${OPTARG};;
            v) set_vervose ;;
            h) 
                echo "$0"
                echo "Brief: "
                echo "    Gra w kółko i krzyżyk"
                echo "Control:"
                echo "    Numpad --> symbole z zakresu 0 do 9 (znaki wewnątrz A B C ... są tylko dla rożróżnienia pionu i poziomu)"
                echo "Options: "
                echo "    -d ARG   -- Zdefiniuj rozmiar kwadratowej planszy. Zamiast ARG podaj długość boku planszy"
                echo "    -v       -- Tryb verbose, do debugowania"
                echo "    -h       -- Pomoc"
                exit 0;
                ;;
        esac
    done
    
    for i in $(eval echo "{0..$DIM}")
    do
        for j in $(eval echo "{0..$DIM}")
        do
            let ch=$i*$TRUE_DIM+$j
            PLANSZA[ch]="${PUSTE}"
        done
    done

    let MAX_RUCHOW=$TRUE_DIM*$TRUE_DIM
}

##
# \brief Animacja Zwycięstwa
##
function koniec {
    local ti=0.2
    wyswietl
    echo -en "#"
    sleep $ti
    echo -en "\r\033[K##"
    sleep $ti
    echo -en "\r\033[K###"
    sleep $ti
    echo -en "\r\033[K####"
    sleep $ti
    echo -en "\r\033[K#### W"
    sleep $ti
    echo -en "\r\033[K#### WY"
    sleep $ti
    echo -en "\r\033[K#### WYGR"
    sleep $ti
    echo -en "\r\033[K#### WYGRA"
    sleep $ti
    echo -en "\r\033[K#### WYGRAŁ "
    sleep $ti
    echo -en "\r\033[K#### WYGRAŁ G"
    sleep $ti
    echo -en "\r\033[K#### WYGRAŁ GR"
    sleep $ti
    echo -en "\r\033[K#### WYGRAŁ GRA"
    sleep $ti
    echo -en "\r\033[K#### WYGRAŁ GRAC"
    sleep $ti
    echo -en "\r\033[K#### WYGRAŁ GRACZ"
    sleep $ti
    echo -en "\r\033[K#### WYGRAŁ GRACZ "
    sleep $ti
    echo -en "\r\033[K#### WYGRAŁ GRACZ $1"
    sleep $ti
    echo -en "\r\033[K#### WYGRAŁ GRACZ $1 "
    sleep $ti
    echo -en "\r\033[K#### WYGRAŁ GRACZ $1 #"
    sleep $ti
    echo -en "\r\033[K#### WYGRAŁ GRACZ $1 ##"
    sleep $ti
    echo -en "\r\033[K#### WYGRAŁ GRACZ $1 ###"
    sleep $ti
    echo -en "\r\033[K#### WYGRAŁ GRACZ $1 ####"
    sleep $ti
    echo -e  "\r\033[K#### WYGRAŁ GRACZ $1 #####"
    exit 0
}

function wyswietl_blad {
    case "${ERROR}" in
        0) ;;
        1) MSG="Złe parametry"  ;;
        2) MSG="Zajęte pole" ;;
        3) MSG="Puste wejście" ;;
    esac
    ERROR=0
    echo "### $MSG"
    MSG=$MSG_0
}

zacznij $@


while [ $KONIEC -eq "0" ]
do
    # Wyświetlanie
    wyswietl

    # Obsługa błędów
    wyswietl_blad

    # Interfejs wejścia
    echo    "gracz:      $GRACZ"
    read -p 'W poziomie: ' POZIOM
    read -p 'W pionie:   ' PION

    # Ewaluacja wejścia
    if [[ ! -z "$POZIOM" ]] && [[ ! -z "$PION" ]]; then
        if [[ POZIOM -le $DIM ]] && [[ POZIOM -le $DIM ]] && [[ POZIOM != "" ]] && [[ POZIOM != "" ]]; then

            # Kalkulacja ID pola
            let ch=POZIOM*TRUE_DIM+PION
            POLE=${PLANSZA[ch]}
            echo "ID : $ch"
            # Czy pole jest zajęte
            if [ "${PUSTE}" = "${POLE}" ]; then

                # Zapisywanie ruchu
                if [ $GRACZ -eq 0 ]
                then 
                    PLANSZA[ch]=X
                else
                    PLANSZA[ch]=O
                fi
                let RUCH++

                # Sprawdz czy doszło do wygranej
                sprawdz_wygrana ${PLANSZA[ch]}
                RESULT=$?
                if [ 1 -eq $RESULT ]; then
                    koniec $GRACZ
                fi

                # Sprawdz czy wyczerpały sie możliowe ruchy
                if [ $MAX_RUCHOW = $RUCH ]; then
                    exit 0
                fi

                # Przekaz pałeczke drugiemu graczowi
                zmiana_gracza

            else
                ERROR=2
            fi
        else
            ERROR=1
        fi
    else
        ERROR=3
    fi
done