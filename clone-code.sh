#!/bin/bash

SRC="/tmp/repos"
DEST="/tmp/chatbot"

if [ ! -d "$SRC" ];
then
    mkdir -p $SRC
fi

repos=(
    "Theldus/wsServer" "zserge/jsmn" "fatihky/gason-c" "tylov/regexp9"
    "sheredom/utf8.h" "deplinenoise/webby" "tylov-fork/mregexp" "c9s/r3"
)

cd $SRC

for repo in "${repos[@]}"
do
    name="$(basename $repo)"
    if [ "$name" == "gason-c" ];
    then
        name="gason"
    fi
    if [ ! -d $name ];
    then
        echo -e "Clone github repos '\033[0;33m$repo\033[0m' to '\033[0;32m$name\033[0m' ..."
        if [ "$name" == "mregexp" ]; then
            git clone --quiet "https://github.com/$repo" -b faster-utf8 --single-branch $name
            cd $name
            git branch -m faster-utf8 master
            cd $SRC
        else
            git clone --quiet "https://github.com/$repo" $name
        fi
    fi
done

if [ ! -d "$DEST" ];
then
    mkdir $DEST
fi

rm -rf $DEST/*

cd $DEST/

echo -e "Modified '\033[0;32mgason\033[0m'"

cp -rf $SRC/gason/gason-c.c gason.c
cp -rf $SRC/gason/gason-c.h gason.h

sed '5,$d' gason.h > aaa.c
echo "extern \"C\" {" >> aaa.c
echo "#endif" >> aaa.c
sed '1,10d' gason.h >> aaa.c
sed -i '130,$d' aaa.c
cat >> aaa.c <<EOF
#ifdef __cplusplus
}
#endif
#endif
EOF
mv aaa.c gason.h
sed -i 's/\/\/ bool           gason_value_to_bool(gason_value_t/bool           gason_value_to_bool(gason_value_t/g' gason.h

sed '80,$d' gason.h | sed '1,75d' | sed 's/gason_value_insert_child/gason_value_prepend_child/g' > nm.txt

sed '80,$d' gason.h > aaa.c
cat nm.txt >> aaa.c
sed '1,79d' gason.h >> aaa.c
rm -rf nm.txt
mv aaa.c gason.h

sed -i 's/"gason-c\.h"/<gason.h>/g' gason.c
sed -i '906,$d' gason.c
sed -i '194d' gason.c
sed -i '2,4d' gason.c

sed '1,98d' gason.c | sed '6,$d' > a.c
sed -i 's/assert(gason_value_get_tag(v) == G_JSON_BOOL);/assert(gason_value_get_tag(v) == G_JSON_TRUE || gason_value_get_tag(v) == G_JSON_FALSE);/' a.c
sed -i 's/return (bool)gason_value_get_payload(v);/return (gason_value_get_tag(v) == G_JSON_TRUE ? true : false);/g' a.c
sed -i 's/\/\*//g' a.c
sed -i 's/\*\///g' a.c


sed '201,$d' gason.c > x.c
echo "  gason_value_insert_child(al, self, propName, val);" >> x.c
sed '1,203d' gason.c >> x.c
mv x.c gason.c

sed '897,$d' gason.c > x.c
echo "  if (length) *length = pos;" >> x.c
sed '1,897d' gason.c >> x.c

mv x.c gason.c

sed '99,$d' gason.c > x.c
cat a.c >> x.c
rm -rf a.c
sed '1,103d' gason.c >> x.c
mv x.c gason.c

sed '184,$d' gason.c | sed '1,141d' | sed '31,38d' | sed 's/gason_value_insert_child/gason_value_prepend_child/g' | sed 's/\/\/ insert to tail/node->next = selfNode;\n    selfNode = node;\n    gason_value_set_payload(self, tag, node);/g' > nn.txt

sed '185,$d' gason.c > x.c
cat nn.txt >> x.c
echo "" >> x.c
sed '1,184d' gason.c >> x.c
rm -rf nn.txt
mv x.c gason.c

echo -e "Modified '\033[0;32mjsmn\033[0m'"

sed '102,465d' $SRC/jsmn/jsmn.h > jsmn.h

sed '24,$d' $SRC/jsmn/jsmn.h > jsmn.c
echo '' >> jsmn.c
echo '#include <jsmn.h>' >> jsmn.c
echo '' >> jsmn.c
sed '464,$d' $SRC/jsmn/jsmn.h | sed '1,102d' >> jsmn.c

sed -i -e "79 i\    case ')':" jsmn.c
sed -i -e "79 i\    case '(':" jsmn.c

sed -i -e "240 i\      type = (c != ']' ? JSMN_OBJECT : JSMN_ARRAY);" jsmn.c
sed -i '239d' jsmn.c

sed -i -e "231 i\      token->type = (c != '[' ? JSMN_OBJECT : JSMN_ARRAY);" jsmn.c
sed -i '230d' jsmn.c

sed -i -e "236 i\    case ')':" jsmn.c
sed -i -e "209 i\    case '(':" jsmn.c

echo -e "Modified '\033[0;32mws\033[0m'"

cp -rf $SRC/wsServer/src/*.c .
cp -rf $SRC/wsServer/include/*.h .

hs=(`ls *.h`)
cs=(`ls *.c`)
ws=""
for c in "${cs[@]}";
do
  if [ "$c" != "ws.c" ];
  then
    if [ "$c" == "jsmn.c" ] || [ "$c" == "gason.c" ]
    then
      continue
    fi
    o="objects/${c/.c/.o}"
    if [ "$ws" == "" ];
    then
      ws="$o"
    else
      ws="$ws $o"
    fi
  fi
  for h in "${hs[@]}";
  do
    sed -i 's/"$h"/<$h>/g' $c
  done
done

sed '263,$d' ws.h | sed '222,225d' | sed '219d' > a.h
sed '263,$d' ws.h | sed '1,260d' | sed 's/ws_sendframe/ws_send_broacast/g' >> a.h
sed '272,275d' ws.h | sed '1,262d' >> a.h
mv a.h ws.h

sed '1717,$d' ws.c | sed -e '539 i\		output = (ssize_t)ws_send_broacast(client, msg, strlen(msg), type);' | \
sed '540,556d' | sed '474d' | sed '472d' > a.c
cat >> a.c <<EOF
/**
 * Send broacast exclude current client
 */
int ws_send_broacast(ws_cli_conn_t * client, const char * msg,
    uint64_t size, int type) {
    int client_sock = -1;
    int output;
    int send_ret;
    int i;
    ws_cli_conn_t *cli;      /* Client.            */

    if (client) {
        client_sock = client->client_sock;
    }
EOF
sed '556,$d' ws.c | sed '1,538d' | \
sed -e 's/^\t//' | sed 's/\t/    /g' | sed -e '6 i\        if (cli->client_sock == client_sock) continue;' | \
sed -e '9 i\            if(type == WS_FR_OP_TXT) {\n                ((void)size);\n                send_ret = ws_sendframe_txt(cli, msg);\n            } else {\n                send_ret = ws_sendframe_bin(cli, msg, size);\n            }\n            if (send_ret != -1)' | \
sed '16d' >> a.c
cat >> a.c <<EOF
    return output;
}
EOF
sed -i -e '1681 i\	if(listen(*sock, MAX_CLIENTS) < 0)\n        panic("Listen failed");' a.c
sed -i '1680d' a.c
mv a.c ws.c

sed '1422,$d' ws.c > a.c
cat >> a.c <<EOF
static void * ws_check_alive(void * data) {
    ((void)data);
EOF
sed '103,$d' $SRC/wsServer/examples/ping/ping.c | sed -e '101 i\#endif' | \
sed -e '99 i\#ifdef WS_PING_TIMEOUT\n		sleep(WS_PING_TIMEOUT);\n#else' | \
sed 's/printf(/DEBUG(/g' | \
sed '1,81d' >> a.c
cat >> a.c <<EOF  
    return NULL;
}
EOF
sed '1687,$d' ws.c | sed '1,1420d' >> a.c
cat >> a.c <<EOF
    /* PING broadcast. */
    if(pthread_create(&ping_thread, NULL, ws_check_alive, (void *)NULL))
        panic("Could not create the ping thread!");
    pthread_detach(ping_thread);
EOF
sed '1,1685d' ws.c >> a.c
sed -i -e '1649 i\	pthread_t ping_thread;     /* Ping thread.           */' a.c
mv a.c ws.c

sed -i -e '51 i\#endif' ws.c
sed -i -e '50 i\#ifdef VALIDATE_UTF8' ws.c

sed -i -e '1718 i\#endif' ws.c
sed -i -e '1717 i\#ifndef DISABLE_VERBOSE' ws.c

sed -i 's/\t/    /g' ws.c
sed -i 's/\t/    /g' ws.h

echo -e "Modified '\033[0;32mutf8.c\033[0m'"

sed '32,$d' utf8.c > a.c
echo '' >> a.c
echo '/* https://github.com/tylov/regexp9/blob/main/utf8_tables.h */' >> a.c
sed '1024,$d' $SRC/regexp9/utf8_tables.h | sed '1d' >> a.c
echo '/* https://github.com/tylov/regexp9/blob/main/utf8_tables.h */' >> a.c
sed '1,31d' utf8.c >> a.c
echo '/* https://github.com/tylov/regexp9/blob/main/utf8_tables.h */' >> a.c
sed '1067,$d' $SRC/regexp9/utf8_tables.h | sed '1,1022d' | sed 's/static inline int utf8/int utf8/g' >> a.c
sed -i 's/static const size_t     cfold_len/\/\/ static const size_t     cfold_len/g' a.c
mv a.c utf8.c

sed '1317,$d' $SRC/utf8.h/utf8.h | sed '1275,1282d' | sed '1,1177d' | \
sed 's/utf8_constexpr14_impl //g' | sed 's/utf8_int32_t/uint32_t/g' | \
sed 's/utf8_int8_t/uint8_t/g' | sed 's/ utf8/ utf8_/g' |  sed 's/\*utf8/* utf8_/g' | \
sed 's/utf8_lwr/utf8_lowercase/g' | sed 's/utf8_upr/utf8_uppercase/g' | \
sed 's/utf8__restrict //g' | sed 's/lwr_cp = utf8_lowercasecodepoint/lwr_cp = utf8_tolower/g' | \
sed 's/lwr_cp = utf8_uppercasecodepoint/lwr_cp = utf8_toupper/g' | \
sed 's/lwr_cp/trans_cp/g' | sed 's/utf8__null/NULL/g' > c.c
sed '547,$d' $SRC/utf8.h/utf8.h | sed '1,513d' | sed 's/utf8_constexpr14_impl //g' | \
sed 's/utf8_int8_t/uint8_t/g' | sed 's/ utf8/ utf8_/g' >> c.c
#echo '' >> utf8.c
#sed '203,$d' $SRC/regexp9/regexp9.c | sed '1,179d' | sed 's/UTF8_OK/UTF8_ACCEPT/g' | \
#sed 's/UTF8_ERROR/UTF8_REJECT/g' | sed 's/Rune/uint32_t/g' | \
#sed 's/inline //g' >> utf8.c
echo '' >> utf8.c
echo '/* https://github.com/sheredom/utf8.h/blob/master/utf8.h */' >> utf8.c
sed '132,134d' c.c >> utf8.c
echo '' >> utf8.c
sed '135,$d' c.c | sed '1,131d' >> utf8.c
sed -i 's/utf8codepoint(/utf8_codepoint(/g' utf8.c
sed -i 's/size_t utf8_nlen(/static size_t utf8_nlen(/g' utf8.c
sed -i 's/utf8_len/utf8_strlen/g' utf8.c
sed -i 's/"utf8.h"/<utf8.h>/g' utf8.c

echo -e "Modified '\033[0;32mutf8.h\033[0m'"

sed '37,$d' utf8.h > a.h
echo '    /* https://github.com/tylov/regexp9/blob/main/utf8_tables.h */' >> a.h
# https://www.cyberciti.biz/faq/unix-linux-sed-print-only-matching-lines-command/
sed -n '/static inline int utf8/p' $SRC/regexp9/utf8_tables.h | sed 's/static inline /    extern /g' | sed 's/) {/);/g' >> a.h
echo '' >> a.h
echo '    /* https://github.com/sheredom/utf8.h/blob/master/utf8.h */' >> a.h
sed '4,$d' c.c | sed -z "s/\n              / /g" | sed -z 's/\n/ /g' | \
sed 's/uint8_t \* utf8/    extern uint8_t * utf8_/g' | sed 's/ {/;/g' >> a.h
echo '' >> a.h
sed 's/size_t utf8_/    extern size_t utf8_/g' c.c | sed 's/void /    extern void /g' | \
sed 's/uint8_t \* utf8_/    extern uint8_t \* utf8_/g' | sed '136d' | sed -n '/extern/p' | \
sed 's/ {/;/g' | sed 's/utf8_len/utf8_strlen/g' >> a.h
sed '1,35d' utf8.h >> a.h
mv a.h utf8.h
rm -rf c.c

echo -e "Modified '\033[0;32mdemo.c\033[0m'"

cp -rf $SRC/wsServer/examples/echo/echo.c demo.c

sed '23,$d' demo.c > a.c
cat >> a.c <<EOF
#include <gason.h>
#include <util.h>
#include <engine.h>
#include <string.h>
EOF
sed '113,$d' demo.c | sed '1,22d' >> a.c
cat >> a.c <<EOF
    gason_allocator_t *al = gason_allocator_new();
    gason_value_t * arr = gason_value_new_type(al, G_JSON_ARRAY, NULL);
    gason_value_add_string(al, arr, NULL, strdup("Milk"));
    gason_value_add_bool(al, arr, NULL, true);
    gason_value_add_bool(al, arr, NULL, false);
    gason_value_add_null(al, arr, NULL);
    gason_value_add_number(al, arr, NULL, 100);
    gason_value_add_number(al, arr, NULL, 10);
    gason_value_add_number(al, arr, NULL, 1);
    char * ret = gason_encode(arr, NULL, 0);
    gason_allocator_deallocate(al);
    printf("%s\n", ret);
    char * s0 = strdup("Nghiên cứu Đại học King's College London và Đại học Leiceste đăng trên Tạp chí Di truyền Con người Mỹ năm 2021 cũng cho thấy");
    printf("s0=%s\n", s0);
    char * s00 = to_lower(s0);
    printf("s0=%s\n%s\n", s0,s00);
    char * s1 = strdup("H'Hen Niê là một hoa hậu và người mẫu người Việt Nam.");
    printf("s1=%s\n", s1);
    char * s11 = to_upper(s1);
    printf("s1=%s\n%s\n", s1,s11);
    printf("%s\n", get_current_dir_name());
    struct engine_t * engine = regex_engine("resources/lexer.lex");
    if (engine) {
        struct engine_t * it = engine;
        for(; it != NULL; it = it->next) {
            printf("name: %s\n", it->name);
            char ** p = it->patterns;
            while(*p) {
                printf("  patern: %s\n", *p);
                p++;
            }
        }
        if(save_regex_engine("regexp.lex", *engine)) {
            printf("Regex is not saved\n");
        } else {
            printf("Regex is saved\n");
        }
    } else {
        printf("Opts\n");
    }
    struct repl_t * repl = repl_engine("resources/repl.lex");
    if(repl) {
        struct repl_t * it = repl;
        for(;it != NULL; it = it->next) {
            printf("regex_replace(/%s/,'%s')\n", it->pattern, it->repl);
        }
        if(save_repl_engine("repl.lex", *repl)) {
            printf("Repl is not saved\n");
        } else {
            printf("Repl is saved\n");
        }
    }
    char ** tokens = split("đồ mi là đồ mi phá ba mi về là ba mi la olala .", " ", NULL);
    if (tokens) {
        while(*tokens) {
            printf("%s -> %s\n", *tokens, (is_syllable(*tokens) ? "true" : "false"));
            tokens++;
        }
    }
EOF
sed '1,112d' demo.c >> a.c
mv a.c demo.c

NT=$'\t'

echo -e "Modified '\033[0;32mregexp9\033[0m'"

cp -rf $SRC/regexp9/regexp9.h regexp.h
cp -rf $SRC/regexp9/regexp9.c regexp.c

sed -i 's/"regexp9.h"/<regexp.h>/g' regexp.c
sed -i 's/"utf8_tables.h"/<utf8.h>/g' regexp.c
sed -i '179d' regexp.c
sed -i 's/UTF8_OK/UTF8_ACCEPT/g' regexp.c
sed -i 's/UTF8_ERROR/UTF8_REJECT/g' regexp.c

sed '94,$d' regexp.h > a.h
echo "const char * cregex_error(int code);" >> a.h
echo "" >> a.h
sed '1,93d' regexp.h >> a.h

mv a.h regexp.h

sed '38,$d' regexp.h > a.h
echo "    creg_ok = 0," >> a.h
sed '1,37d' regexp.h >> a.h
mv a.h regexp.h

cat >> regexp.c <<EOF
const char * cregex_error(int code) {
    switch((cregex_error_t)code) {
        case creg_nomatch: return "No match";
        case creg_matcherror: return "Match error";
        case creg_outofmemory: return "Out of memory";
        case creg_unmatchedleftparenthesis: return "Unmatched left parenthesis";
        case creg_unmatchedrightparenthesis: return "Unmatched right parenthesis";
        case creg_toomanysubexpressions: return "Too many sub expressions";
        case creg_toomanycharacterclasses: return "Too many character classes";
        case creg_malformedcharacterclass: return "Malformed character class";
        case creg_missingoperand: return "Missing operand";
        case creg_unknownoperator: return "Unknown operator";
        case creg_operandstackoverflow: return "Operand stackoverflow";
        case creg_operatorstackoverflow: return "Operator stackoverflow";
        case creg_operatorstackunderflow: return "Operator stack underflow";
        case creg_ok: return NULL;
        default: return "Unknown";
    }
}
EOF

sed -i '867,870d' regexp.c
sed -i '861,863d' regexp.c
sed -i '854,856d' regexp.c
sed -i '586,626d' regexp.c

if [ ! -d resources ]; then
    mkdir -p resources
fi

rm -rf resources/*

echo "Create lexer"

cat > resources/lexer.lex <<EOF
# Abbreviations

Ph\.D\.
U\.S\.A
[A-ZĐ]+&[A-ZĐ]+
\d+\/\d+\/[A-ZĐ]+-[A-ZĐ]+
[A-ZĐ]+\.[A-ZĐ]+
[A-ZĐ]+\/[A-ZĐ]+
[A-ZÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬĐÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴ]+(?:.{W}+)+.?
[A-ZĐ]+\.
\d+[A-Z]+\d*-\d+\.\d+
\d+[A-Z]+\d*-\d+
Tp\.
Mr\.
Mrs\.
Ms\.
Dr\.
ThS\.

# Specials

==>
->
\.{2,}
>{2,}

# Web

\s*((http[s]?:\/\/(www\.)?|ftp:\/\/(www\.)?|www\.){1}([0-9A-Za-z-\.@:%_+~#=]+)+((\.[a-zA-Z]{2,3})+)(/(.)*)?(\?(.)*)?)\s*

# Domain

\s*([A-Za-z0-9]+([\-\.]{1}[A-Za-z0-9]+)*\.[A-Za-z]{2,6})\s*

# Email

(^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$)

# Datetime

\d{1,2}\/\d{1,2}\/\d{1,4}
\d{1,2}\/\d{1,4}
\d{1,2}\/\d{1,2}(\/\d+)?
\d{1,2}-\d{1,2}(-\d+)?

# Digit

\d+([\.,_]\d+)+

# Non word

[^aáàạảãăắằặẳẵâấầậẩẫbcdđeéèẹẻẽêếềệểễfghiíìịỉĩjklmnoóòọỏõôồốộổỗơớờợởỡpqrstuúùụủũưứừựửữvwxyýỳỵỷỹzAÁÀẠẢÃĂẮẰẶẲẴÂẤẦẬẨẪBCDĐEÉÈẸẺẼÊẾỀỆỂỄFGHIÍÌỊỈĨJKLMNOÓÒỌỎÕÔỐỒỘỔỖƠỚỜỢỞỠPQRSTUÚÙỤỦŨƯỨỪỰỬỮVWXYÝỲỴỶỸZ0-9\s]

# Word

[aáàạảãăắằặẳẵâấầậẩẫbcdđeéèẹẻẽêếềệểễfghiíìịỉĩjklmnoóòọỏõôồốộổỗơớờợởỡpqrstuúùụủũưứừựửữvwxyýỳỵỷỹzAÁÀẠẢÃĂẮẰẶẲẴÂẤẦẬẨẪBCDĐEÉÈẸẺẼÊẾỀỆỂỄFGHIÍÌỊỈĨJKLMNOÓÒỌỎÕÔỐỒỘỔỖƠỚỜỢỞỠPQRSTUÚÙỤỦŨƯỨỪỰỬỮVWXYÝỲỴỶỸZ0-9]+
EOF

echo "Create preg"

cat > resources/repl.lex <<EOF
(\.{2,})

(\-{2,})

…
...


[“”]
"

[‘’]
'

–
-

%08
 

ð
đ

\s+
 
EOF

echo "Create snoovatar-snoo.png avatar"

echo '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' | base64 -d > resources/snoovatar-snoo.png

echo "Create util.h"

cat > util.h <<EOF
#ifndef __UTIL_H
#define __UTIL_H

#include <stdbool.h>

char * ltrim(char *, const char *);
char * ltrim_copy(char *, const char *);
char * rtrim(char *, const char *);
char * rtrim_copy(char *, const char *);
char * trim(char *, const char *);
char * trim_copy(char *, const char *);
char ** split(const char *, const char *, int *);
bool file_exists (const char *);
const char * get_current_dir_name(void);
char * to_lower(char *);
char * to_upper(char *);
//char * vn_typos(char *);
int is_syllable(const char *);

#endif
EOF

echo "Create util.c"

cat > util.c <<EOF
#include <util.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <sys/stat.h>
#include <libgen.h>
#include <unistd.h>
#include <limits.h>
#include <utf8.h>
#include <regexp.h>
#include <stdio.h>

// https://stackoverflow.com/a/1431206
static int is_delim(int ch, const char *s) {
    if (!s) return isspace(ch);
    const char * p = s;
    while(*p) {
        if (*p == ch) return 1;
        p++;
    }
    return 0;
}
char * ltrim(char * s, const char * d) {
    while(is_delim(*s, d)) s++;
    return s;
}
char * ltrim_copy(char * s, const char * d) {
    s = ltrim(s, d);
    return s;
}
char * rtrim(char * s, const char * d) {
    char * back = s + strlen(s);
    while(is_delim(*--back, d));
    *(back + 1) = '\0';
    return s;
}
char * rtrim_copy(char * s, const char * d) {
    s = rtrim(s,d);
    return s;
}
char * trim(char * s, const char * d) {
    return rtrim(ltrim(s, d), d);
}
char * trim_copy(char * s, const char * d) {
    s = trim(s,d);
    return s;
}
// https://stackoverflow.com/a/27140953
char ** split(const char * str, const char * delim, int * len) {
    char ** res = NULL;
    char * part;
    int i = 0;
    char * aux = strdup(str);
    part = strtok(aux, delim);
    while(part) {
        res = (char **)realloc(res, (i + 1) * sizeof(char *));
        *(res + i) = strdup(part);
        part = strtok(NULL, delim);
        i++;
    }
    res = (char **)realloc(res, i * sizeof(char *));
    *(res + i) = NULL;
    if(len) {
        *len = i;
    }
    return res;
}
bool file_exists (const char * filepath) {
    struct stat buff;
    return (stat (filepath, &buff) == 0);
}
// https://stackoverflow.com/a/23943306
const char * get_current_dir_name(void) {
    char result[PATH_MAX];
    ssize_t count = readlink("/proc/self/exe", result, PATH_MAX);
    if (count != -1) {
        return dirname(result);
    }
    return NULL;
}
char * to_lower(char * s) {
    utf8_lowercase((uint8_t *)s);
    return s;
}
char * to_upper(char * s) {
    utf8_uppercase((uint8_t *)s);
    return s;
}
static uint32_t utf8_peek(const uint8_t * s)
{
    uint32_t cp = 0;
    (void)utf8_codepoint((uint8_t *)s, &cp);
    return cp;
}
static const uint8_t * utf8_next(const uint8_t * s)
{
    if (*s == 0)
        return NULL;

    uint32_t cp = 0;
    uint8_t *pn = utf8_codepoint((uint8_t *)s, &cp);
    (void)cp;
    return pn;
}
static const uint8_t * utf8_at(const uint8_t * s, size_t index)
{
    if(index == 0) return s;
    size_t i = 0;
    while(*s)
    {
        i++;
        s = utf8_next(s);
        if (i == index) return s;
    }
    return NULL;
}
static uint32_t utf8_peek_at(const uint8_t * s, size_t index)
{
    const uint8_t * e = utf8_at(s, index);
    if(e == NULL) return 0;
    return utf8_peek(e);
}
static uint32_t normal_non_tones(uint32_t cp, int lower) {
    switch(cp) {
        case 0x0061 /* a */ : case 0x00e0 /* à */ : case 0x00e1 /* á */ : 
        case 0x1ea1 /* ạ */ : case 0x1ea3 /* ả */ : case 0x00e3 /* ã */ : {
            /* a */
            cp = 0x0061;
        } break;
        case 0x00e2 /* â */ : case 0x1ea7 /* ầ */ : case 0x1ea5 /* ấ */ : 
        case 0x1ead /* ậ */ : case 0x1ea9 /* ẩ */ : case 0x1eab /* ẫ */ : {
            /* â */
            cp = 0x00e2;
        } break;
        case 0x0103 /* ă */ : case 0x1eb1 /* ằ */ : case 0x1eaf /* ắ */ : 
        case 0x1eb7 /* ặ */ : case 0x1eb3 /* ẳ */ : case 0x1eb5 /* ẵ */ : {
            /* ă */
            cp = 0x0103;
        } break;
        case 0x0041 /* A */ : case 0x00c0 /* À */ : case 0x00c1 /* Á */ : 
        case 0x1ea0 /* Ạ */ : case 0x1ea2 /* Ả */ : case 0x00c3 /* Ã */ : {
            /* A */
            cp = 0x0041;
        } break;
        case 0x00c2 /* Â */ : case 0x1ea6 /* Ầ */ : case 0x1ea4 /* Ấ */ : 
        case 0x1eac /* Ậ */ : case 0x1ea8 /* Ẩ */ : case 0x1eaa /* Ẫ */ : {
            /* Â */
            cp = 0x00c2;
        } break;
        case 0x0102 /* Ă */ : case 0x1eb0 /* Ằ */ : case 0x1eae /* Ắ */ : 
        case 0x1eb6 /* Ặ */ : case 0x1eb2 /* Ẳ */ : case 0x1eb4 /* Ẵ */ : {
            /* Ă */
            cp = 0x0102;
        } break;
        case 0x0065 /* e */ : case 0x00e8 /* è */ : case 0x00e9 /* é */ : 
        case 0x1eb9 /* ẹ */ : case 0x1ebb /* ẻ */ : case 0x1ebd /* ẽ */ : {
            /* e */
            cp = 0x0065;
        } break;
        case 0x00ea /* ê */ : case 0x1ec1 /* ề */ : case 0x1ebf /* ế */ : 
        case 0x1ec7 /* ệ */ : case 0x1ec3 /* ể */ : case 0x1ec5 /* ễ */ : {
            /* ê */
            cp = 0x00ea;
        } break;
        case 0x0045 /* E */ : case 0x00c8 /* È */ : case 0x00c9 /* É */ : 
        case 0x1eb8 /* Ẹ */ : case 0x1eba /* Ẻ */ : case 0x1ebc /* Ẽ */ : {
            /* E */
            cp = 0x0045;
        } break;
        case 0x00ca /* Ê */ : case 0x1ec0 /* Ề */ : case 0x1ebe /* Ế */ : 
        case 0x1ec6 /* Ệ */ : case 0x1ec2 /* Ể */ : case 0x1ec4 /* Ễ */ : {
            /* Ê */
            cp = 0x00ca;
        } break;
        case 0x0069 /* i */ : case 0x00ec /* ì */ : case 0x00ed /* í */ : 
        case 0x1ecb /* ị */ : case 0x1ec9 /* ỉ */ : case 0x0129 /* ĩ */ : {
            /* i */
            cp = 0x0069;
        } break;
        case 0x0049 /* I */ : case 0x00cc /* Ì */ : case 0x00cd /* Í */ : 
        case 0x1eca /* Ị */ : case 0x1ec8 /* Ỉ */ : case 0x0128 /* Ĩ */ : {
            /* I */
            cp = 0x0049;
        } break;
        case 0x006f /* o */ : case 0x00f2 /* ò */ : case 0x00f3 /* ó */ : 
        case 0x1ecd /* ọ */ : case 0x1ecf /* ỏ */ : case 0x00f5 /* õ */ : {
            /* o */
            cp = 0x006f;
        } break;
        case 0x00f4 /* ô */ : case 0x1ed3 /* ồ */ : case 0x1ed1 /* ố */ : 
        case 0x1ed9 /* ộ */ : case 0x1ed5 /* ổ */ : case 0x1ed7 /* ỗ */ : {
            /* ô */
            cp = 0x00f4;
        } break;
        case 0x01a1 /* ơ */ : case 0x1edd /* ờ */ : case 0x1edb /* ớ */ : 
        case 0x1ee3 /* ợ */ : case 0x1edf /* ở */ : case 0x1ee1 /* ỡ */ : {
            /* ơ */
            cp = 0x01a1;
        } break;
        case 0x004f /* O */ : case 0x00d2 /* Ò */ : case 0x00d3 /* Ó */ : 
        case 0x1ecc /* Ọ */ : case 0x1ece /* Ỏ */ : {
            /* O */
            cp = 0x004f;
        } break;
        case 0x00d4 /* Ô */ : case 0x1ed2 /* Ồ */ : case 0x1ed0 /* Ố */ : 
        case 0x1ed8 /* Ộ */ : case 0x1ed4 /* Ổ */ : case 0x1ed6 /* Ỗ */ : {
            /* Ô */
            cp = 0x00d4;
        } break;
        case 0x01a0 /* Ơ */ : case 0x1edc /* Ờ */ : case 0x1eda /* Ớ */ : 
        case 0x1ee2 /* Ợ */ : case 0x1ede /* Ở */ : case 0x1ee0 /* Ỡ */ : {
            /* Ơ */
            cp = 0x01a0;
        } break;
        case 0x0075 /* u */ : case 0x00f9 /* ù */ : case 0x00fa /* ú */ : 
        case 0x1ee5 /* ụ */ : case 0x1ee7 /* ủ */ : case 0x0169 /* ũ */ : {
            /* u */
            cp = 0x0075;
        } break;
        case 0x01b0 /* ư */ : case 0x1eeb /* ừ */ : case 0x1ee9 /* ứ */ : 
        case 0x1ef1 /* ự */ : case 0x1eed /* ử */ : case 0x1eef /* ữ */ : {
            /* ư */
            cp = 0x01b0;
        } break;
        case 0x0055 /* U */ : case 0x00d9 /* Ù */ : case 0x00da /* Ú */ : 
        case 0x1ee4 /* Ụ */ : case 0x1ee6 /* Ủ */ : case 0x0168 /* Ũ */ : {
            /* U */
            cp = 0x0055;
        } break;
        case 0x01af /* Ư */ : case 0x1eea /* Ừ */ : case 0x1ee8 /* Ứ */ : 
        case 0x1ef0 /* Ự */ : case 0x1eec /* Ử */ : case 0x1eee /* Ữ */ : {
            /* Ư */
            cp = 0x01af;
        } break;
        case 0x0079 /* y */ : case 0x1ef3 /* ỳ */ : case 0x00fd /* ý */ : 
        case 0x1ef5 /* ỵ */ : case 0x1ef7 /* ỷ */ : case 0x1ef9 /* ỹ */ : {
            /* y */
            cp = 0x0079;
        } break;
        case 0x0059 /* Y */ : case 0x1ef2 /* Ỳ */ : case 0x00dd /* Ý */ : 
        case 0x1ef4 /* Ỵ */ : case 0x1ef6 /* Ỷ */ : case 0x1ef8 /* Ỹ */ : {
            /* Y */
            cp = 0x0059;
        } break;
        default: break;
    }
    return lower == 0 ? cp : utf8_tolower(cp);
}
int is_syllable(const char * str) {
    uint8_t * s = (uint8_t *)str;
    uint32_t cp = normal_non_tones(utf8_peek(s), 1);
    if (cp == 0x61) { /* a */
        if(utf8_strlen(s) > 3) return 0;
        const uint8_t * e = utf8_next(s);
        if(e == NULL || *e == '\0') return 1;
        uint32_t np = normal_non_tones(utf8_peek(e), 1);
        /* a, ac, ach, ai, am, an, ang, anh, ao, ap, at, au, ay. */
        if(
            np == 0x69 /* i */ || np == 0x6d /* m */ || np == 0x6f /* o */ ||
            np == 0x70 /* p */ || np == 0x74 /* t */ || np == 0x75 /* u */ ||
            np == 0x79 /* y */
        ) {
            if(*(e + utf8_codepointcalcsize(e)) != '\0') return 0;
            return 1;
        }
        if(np == 0x63 /* c */) {
            uint32_t up = normal_non_tones(utf8_peek_at(e, 1), 1);
            if(up == 0) return 1;
            if(up == 0x68 /* h */) {
                if(utf8_peek_at(e, 2) != 0) return 0;
                return 1;
            }
            return 0;
        }
        if(np == 0x6e /* n */) {
            uint32_t up = normal_non_tones(utf8_peek_at(e, 1), 1);
            if(up == 0) return 1;
            if(up == 0x67 /* g */ || up == 0x68 /* h */) {
                if(utf8_peek_at(e, 2) != 0) return 0;
                return 1;
            }
            return 0;
        }
        return 0;
    }
    if (cp == 0x103) { /* ă */
        if(utf8_strlen(s) > 3) return 0;
        const uint8_t * e = utf8_next(s);
        if(e == NULL || *e == '\0') return 1;
        uint32_t np = normal_non_tones(utf8_peek(e), 1);
        /* ă, ăc, ăm, ăn, ăng, ăp, ăt. */
        if(
            np == 0x63 /* c */ || np == 0x6d /* m */ || np == 0x70 /* p */ ||
            np == 0x74 /* t */
        ) {
            if(*(e + utf8_codepointcalcsize(e)) != '\0') return 0;
            return 1;
        }
        if(np == 0x6e /* n */) {
            uint32_t up = normal_non_tones(utf8_peek_at(e, 1), 1);
            if(up == 0) return 1;
            if(up == 0x67 /* g */) {
                if(utf8_peek_at(e, 2) != 0) return 0;
                return 1;
            }
            return 0;
        }
        return 0;
    }
    if (cp == 0xe2) { /* â */
        if(utf8_strlen(s) > 3) return 0;
        const uint8_t * e = utf8_next(s);
        if(e == NULL || *e == '\0') return 1;
        uint32_t np = normal_non_tones(utf8_peek(e), 1);
        /* â, âc, âm, ân, âng, âp, ât, âu, ây. */
        if(
            np == 0x63 /* c */ || np == 0x6d /* m */ || np == 0x70 /* p */ ||
            np == 0x74 /* t */ || np == 0x75 /* u */ || np == 0x79 /* y */
        ) {
            if(*(e + utf8_codepointcalcsize(e)) != '\0') return 0;
            return 1;
        }
        if(np == 0x6e /* n */) {
            uint32_t up = normal_non_tones(utf8_peek_at(e, 1), 1);
            if(up == 0) return 1;
            if(up == 0x67 /* g */) {
                if(utf8_peek_at(e, 2) != 0) return 0;
                return 1;
            }
            return 0;
        }
        return 0;
    }
    if (cp == 0x65) { /* e */
        if(utf8_strlen(s) > 3) return 0;
        const uint8_t * e = utf8_next(s);
        if(e == NULL || *e == '\0') return 1;
        uint32_t np = normal_non_tones(utf8_peek(e), 1);
        /* e, ec, em, en, eng, eo, ep, et. */
        if(
            np == 0x63 /* c */ || np == 0x6d /* m */ || np == 0x6f /* o */ ||
            np == 0x70 /* p */ || np == 0x74 /* t */
        ) {
            if(*(e + utf8_codepointcalcsize(e)) != '\0') return 0;
            return 1;
        }
        if(np == 0x6e /* n */) {
            uint32_t up = normal_non_tones(utf8_peek_at(e, 1), 1);
            if(up == 0) return 1;
            if(up == 0x67 /* g */) {
                if(utf8_peek_at(e, 2) != 0) return 0;
                return 1;
            }
            return 0;
        }
        return 0;
    }
    if (cp == 0xea) { /* ê */
        if(utf8_strlen(s) > 3) return 0;
        const uint8_t * e = utf8_next(s);
        if(e == NULL || *e == '\0') return 1;
        uint32_t np = normal_non_tones(utf8_peek(e), 1);
        /* ê, êch, ênh, êm, ên, êp, êt, êu. */
        if(
            np == 0x6d /* m */ || np == 0x70 /* p */ || np == 0x74 /* t */ ||
            np == 0x75 /* u */
        ) {
            if(*(e + utf8_codepointcalcsize(e)) != '\0') return 0;
            return 1;
        }
        if(np == 0x63 /* c */) {
            uint32_t up = normal_non_tones(utf8_peek_at(e, 1), 1);
            if(up == 0) return 1;
            if(up == 0x68 /* h */) {
                if(utf8_peek_at(e, 2) != 0) return 0;
                return 1;
            }
            return 0;
        }
        if(np == 0x6e /* n */) {
            uint32_t up = normal_non_tones(utf8_peek_at(e, 1), 1);
            if(up == 0) return 1;
            if(up == 0x67 /* g */) {
                if(utf8_peek_at(e, 2) != 0) return 0;
                return 1;
            }
            return 0;
        }
        return 0;
    }
    if (cp == 0x69) { /* i */
        if(utf8_strlen(s) > 4) return 0;
        const uint8_t * e = utf8_next(s);
        if(e == NULL || *e == '\0') return 1;
        uint32_t np = normal_non_tones(utf8_peek(e), 1);
        /* i, ich, im, in, inh, ip, it, iu. */
        /* ia, iêc, iêm, iên, iêng, iêp, iêt, iêu. */
        if(
            np == 0x6d /* m */ || np == 0x61 /* a */ || np == 0x70 /* p */ ||
            np == 0x74 /* t */ || np == 0x75 /* u */
        ) {
            if(*(e + utf8_codepointcalcsize(e)) != '\0') return 0;
            return 1;
        }
        if(np == 0x63 /* c */) {
            uint32_t up = normal_non_tones(utf8_peek_at(e, 1), 1);
            if(up == 0) return 1;
            if(up == 0x68 /* h */) {
                if(utf8_peek_at(e, 2) != 0) return 0;
                return 1;
            }
            return 0;
        }
        if(np == 0x6e /* n */) {
            uint32_t up = normal_non_tones(utf8_peek_at(e, 1), 1);
            if(up == 0) return 1;
            if(up == 0x67 /* g */ || up == 0x68 /* h */) {
                if(utf8_peek_at(e, 2) != 0) return 0;
                return 1;
            }
            return 0;
        }
        if(np == 0xea /* ê */) {
            uint32_t up = normal_non_tones(utf8_peek_at(e, 1), 1);
            if(up == 0) return 1;
            if(
                up == 0x63 /* c */ || up == 0x6d /* m */ || up == 0x70 /* p */ ||
                up == 0x75 /* u */ || up == 0x74 /* t */
            ) {
                if(utf8_peek_at(e, 2) != 0) return 0;
                return 1;
            }
            if(up == 0x6e /* n */) {
                if(utf8_peek_at(e, 2) == 0) return 1;
                if(utf8_peek_at(e, 2) != 0x67 /* g */ || utf8_peek_at(e, 2) != 0x47 /* G */) {
                    return 1;
                }
                return 0;
            }
            return 0;
        }
        return 0;
    }
    if (cp == 0x6f) { /* o */
        if(utf8_strlen(s) > 4) return 0;
        const uint8_t * e = utf8_next(s);
        if(e == NULL || *e == '\0') return 1;
        uint32_t np = normal_non_tones(utf8_peek(e), 1);
        /* o, oc, oi, om, on, ong, op, ot, oong, ooc. */
        /* oa, oac, oach, oai, oam, oan, oang, oanh, oao, oap, oat, oay, */
        /* oăc, oăm, oăn, oăng, oăt, */
        /* oe, oen, oeo, oet; oem, oeng */
        if(
            np == 0x63 /* c */ || np == 0x69 /* i */ || np == 0x6d /* m */ ||
            np == 0x70 /* p */ || np == 0x74 /* t */
        ) {
            if(*(e + utf8_codepointcalcsize(e)) != '\0') return 0;
            return 1;
        }
        if(np == 0x6e /* n */) {
            uint32_t up = normal_non_tones(utf8_peek_at(e, 1), 1);
            if(up == 0) return 1;
            if(up == 0x67 /* g */) {
                if(utf8_peek_at(e, 2) != 0) return 0;
                return 1;
            }
            return 0;
        }
        if(np == 0x6f /* o */) {
            uint32_t up = normal_non_tones(utf8_peek_at(e, 1), 1);
            if(up == 0) return 1;
            if(up == 0x6f /* o */) {
                if (utf8_peek_at(e, 2) == 0) return 1;
                if (
                    (utf8_peek_at(e, 2) == 0x6e /* n */ || utf8_peek_at(e, 2) == 0x4e /* N */) &&
                    (utf8_peek_at(e, 3) == 0x67 /* g */ || utf8_peek_at(e, 3) == 0x47 /* G */)
                ) return 1;
                if(utf8_peek_at(e, 2) == 0x63 /* c */ || utf8_peek_at(e, 2) == 0x43 /* C */) {
                    if(utf8_peek_at(e, 3) != 0) return 0;
                    return 1;
                }
                return 0;
            }
            return 0;
        }
        if(np == 0x61 /* a */) {
            uint32_t up = normal_non_tones(utf8_peek_at(e, 1), 1);
            if(up == 0) return 1;
            if(up == 0x63 /* c */) {
                if(
                    utf8_peek_at(e, 2) == 0 ||
                    (
                        (
                            utf8_peek_at(e, 2) == 0x68 /* h */ ||
                            utf8_peek_at(e, 2) == 0x48 /* H */
                        ) &&
                        utf8_peek_at(e, 3) == 0
                    )
                ) {
                    return 1;
                }
                return 0;
            }
            if (up == 0x6e /* n */) {
                uint32_t ep = normal_non_tones(utf8_peek_at(e, 2), 1);
                if (ep == 0) return 1;
                if (ep == 0x68 /* h */ || ep == 0x67 /* g */) return 1;
                return 0;
            }
            if(
                up == 0x63 /* c */ || up == 0x6d /* m */ || up == 0x70 /* p */ ||
                up == 0x75 /* u */ || up == 0x79 /* y */ ||
                up == 0x74 /* t */ || up == 0x69 /* i */
            ) {
                if(utf8_peek_at(e, 2) != 0) return 0;
                return 1;
            }
            return 0;
        }
        if(np == 0x103 /* ă */) {
            uint32_t up = normal_non_tones(utf8_peek_at(e, 1), 1);
            if(up == 0) return 1;
            if(
                up == 0x6d /* m */ || up == 0x6e /* n */ || up == 0x74 /* t */ ||
                up == 0x63 /* c */
            ) {
                if(utf8_peek_at(e, 2) != 0) return 0;
                return 1;
            }
            return 0;
        }
        if(np == 0x65 /* e */) {
            uint32_t up = normal_non_tones(utf8_peek_at(e, 1), 1);
            if(up == 0) return 1;
            if(up == 0x6d /* m */ || up == 0x6e /* n */ || up == 0x74 /* t */) {
                if(utf8_peek_at(e, 2) != 0) return 0;
                return 1;
            }
            return 0;
        }
        return 0;
    }
    if (cp == 0xf4) { /* ô */
        if(utf8_strlen(s) > 3) return 0;
        const uint8_t * e = utf8_next(s);
        if(e == NULL || *e == '\0') return 1;
        uint32_t np = normal_non_tones(utf8_peek(e), 1);
        /* ô, ôc, ôi, ôm, ôn, ông, ôp, ôt. */
        if(
            np == 0x63 /* c */ || np == 0x69 /* i */ || np == 0x6d /* m */ ||
            np == 0x70 /* p */ || np == 0x74 /* t */
        ) {
            if(*(e + utf8_codepointcalcsize(e)) != '\0') return 0;
            return 1;
        }
        if(np == 0x6e /* n */) {
            uint32_t up = normal_non_tones(utf8_peek_at(e, 1), 1);
            if(up == 0) return 1;
            if(up == 0x67 /* g */) {
                if(utf8_peek_at(e, 2) != 0) return 0;
                return 1;
            }
            return 0;
        }
        return 0;
    }
    if (cp == 0x1a1) { /* ơ */
        if(utf8_strlen(s) > 3) return 0;
        const uint8_t * e = utf8_next(s);
        if(e == NULL || *e == '\0') return 1;
        uint32_t np = normal_non_tones(utf8_peek(e), 1);
        /* ơ, ơi, ơm, ơn, ơp, ơt. */
        if(
            np == 0x69 /* i */ || np == 0x6d /* m */ || np == 0x6e /* n */ ||
            np == 0x70 /* p */ || np == 0x74 /* t */
        ) {
            if(*(e + utf8_codepointcalcsize(e)) != '\0') return 0;
            return 1;
        }
        return 0;
    }
    if (cp == 0x75) { /* u */
        if(utf8_strlen(s) > 4) return 0;
        const uint8_t * e = utf8_next(s);
        if(e == NULL || *e == '\0') return 1;
        uint32_t np = normal_non_tones(utf8_peek(e), 1);
        /* u, uc, ui, um, un, ung, up, ut. */
        /* ua, uôc, uôi, uôm, uôn, uông, uôt. */
        /* uơ, uê, uênh, uêch. */
        /* uy, uych, uynh, uyt, uyu; uyn, uyp. */
        /* uya, uyên, uyêt. */
        if (
            np == 0x63 /* c */ || np == 0x69 /* i */ || np == 0x6d /* m */ ||
            np == 0x70 /* p */ || np == 0x74 /* t */ || np == 0x61 /* a */ ||
            np == 0x1a1 /* ơ */
        ) {
            if (utf8_peek_at(e, 2) != 0) return 0;
            return 1;
        }
        if(np == 0x6e /* n */) {
            uint32_t ep = normal_non_tones(utf8_peek_at(e, 1), 1);
            if(ep == 0 || ep == 0x67 /* g */) return 1;
            return 0;
        } else if(np == 0xf4 /* ô */) {
            uint32_t ep = normal_non_tones(utf8_peek_at(e, 1), 1);
            if (ep == 0x63 /* c */ || ep == 0x69 /* i */ || ep == 0x6d /* m */ || ep == 0x6e /* n */ || ep == 0x74 /* t */) {
                uint32_t c = normal_non_tones(utf8_peek_at(e, 2), 1);
                if(ep != 0x6e /* n */) {
                    if (c == 0) return 1;
                    return 0;
                }
                if (c == 0 || c == 0x67 /* g */) {
                    return 1;
                }
            }
            return 0;
        } else if(np == 0xea /* ê */) {
            uint32_t ep = normal_non_tones(utf8_peek_at(e, 1), 1);
            if(ep == 0) return 1;
            if (ep == 0x6e /* n */ || ep == 0x63 /* c */) {
                uint32_t c = normal_non_tones(utf8_peek_at(e, 2), 1);
                if (c == 0) return 0;
                if(c == 0x68 /* h */) return 1;
            }
            return 0;
        } else if(np == 0x79 /* y */) {
            uint32_t ep = normal_non_tones(utf8_peek_at(e, 1), 1);
            if(ep == 0) return 1;
            if (ep == 0x6e /* n */ || ep == 0x63 /* c */) {
                uint32_t c = normal_non_tones(utf8_peek_at(e, 2), 1);
                if (c == 0) {
                    if (ep == 0x68 /* h */) return 0;
                    return 1;
                }
                if(c == 0x68 /* h */) return 1;
                return 0;
            }
            if (ep == 0x74 /* t */ || ep == 0x75 /* u */ || ep == 0x70 /* p */ || ep == 0x61 /* a */) {
                if (utf8_peek_at(e, 2) != 0) return 0;
                return 1;
            }
            if (ep == 0xea /* ê */) {
                uint32_t c = normal_non_tones(utf8_peek_at(e, 2), 1);
                if (c == 0) return 0;
                if (c != 0x6e /* n */ && c != 0x74 /* t */) return 0;
                return 1;
            }
        }
        return 0;
    }
    if (cp == 0x1b0) { /* ư */
        if(utf8_strlen(s) > 4) return 0;
        const uint8_t * e = utf8_next(s);
        if(e == NULL || *e == '\0') return 1;
        uint32_t np = normal_non_tones(utf8_peek(e), 1);
        /* ư, ưc, ưi, ưu, ưng, ưt, ưm */
        /* ưa, ươc, ươi, ươm, ươn, ương, ươp, ươt, ươu. */
        if (
            np == 0x63 /* c */ || np == 0x75 /* u */ || np == 0x6d /* m */ ||
            np == 0x74 /* t */ || np == 0x61 /* a */
        ) {
            if (utf8_peek_at(e, 2) != 0) return 0;
            return 1;
        }
        if (np == 0x6e /* n */) {
            if (utf8_peek_at(e, 2) == 0) return 1;
            if(utf8_peek_at(e, 2) == 0x67 /* g */ || utf8_peek_at(e, 2) == 0x47 /* G */) {
                return 1;
            }
            return 0;
        }
        if (np == 0x1a1 /* ơ */) {
            uint32_t ep = normal_non_tones(utf8_peek_at(e, 1), 1);
            if (ep == 0) return 0;
            if(
                ep == 0x63 /* c */ || ep == 0x69 /* i */ || ep == 0x6d /* m */ ||
                ep == 0x70 /* p */ || ep == 0x74 /* t */ || ep == 0x75 /* u */
            ) {
                return 1;
            }
            if(ep == 0x6e /* n */) {
                if (utf8_peek_at(e, 2) == 0) return 1;
                if(utf8_peek_at(e, 2) == 0x67 /* g */ || utf8_peek_at(e, 2) == 0x47 /* G */) {
                    return 1;
                }
            }
        }
        return 0;
    }
    if (cp == 0x79) { /* y */
        if(utf8_strlen(s) > 4) return 0;
        const uint8_t * e = utf8_next(s);
        if(e == NULL || *e == '\0') return 1;
        uint32_t np = normal_non_tones(utf8_peek(e), 1);
        /* yêm, yên, yêng, yêt, yêu. */
        if (np != 0xea /* ê */) return 0;
        uint32_t up = normal_non_tones(utf8_peek_at(e, 1), 1);
        if (up == 0x6d /* m */ || up == 0x74 /* t */ || up == 0x75 /* u */) {
            if (utf8_peek_at(e, 2) != 0) return 0;
            return 1;
        }
        if (up == 0x6e /* n */) {
            if (utf8_peek_at(e, 2) == 0 || utf8_peek_at(e, 2) == 0x67 /* g */ || utf8_peek_at(e, 2) == 0x47 /* G */) return 1;            
        }
        return 0;
    }
    if(
        cp == 0x62 /* b */ || cp == 0x111 /* đ */ || cp == 0x68 /* h */ || 
        cp == 0x6c /* l */ || cp == 0x6d /* m */ || cp == 0x72 /* r */ || 
        cp == 0x73 /* s */ || cp == 0x76 /* v */ || cp == 0x78 /* x */ ||
        cp == 0x64 /* d */
    ) {
        return is_syllable((const char *)utf8_next(s));
    }
    uint32_t np = normal_non_tones(utf8_peek(s + 1), 1);
    if(cp == 0x63) { /* c */
        if(np == 0x68 /* h */) {
            return is_syllable((const char *)(s + 2));
        }
        return is_syllable((const char *)(s + 1));
    }
    if(cp == 0x67) { /* g */
        if(np == 0x68 /* h */ || np == 0x69 /* i */) {
            return is_syllable((const char *)(s + 2));
        }
        return is_syllable((const char *)(s + 1));
    }
    if(cp == 0x6b) { /* k */
        if(np == 0x68 /* h */) {
            return is_syllable((const char *)(s + 2));
        }
        return is_syllable((const char *)(s + 1));
    }
    if(cp == 0x6e) { /* n */
        if(np == 0x67 /* g */ || np == 0x68 /* h */) {
            if(np == 0x67 /* g */ && (utf8_peek(s + 2) == 0x68 /* h */ || utf8_peek(s + 2) == 0x48 /* H */)) {
                if(*(s + 3) == '\0') return 1;
                uint32_t n3 = normal_non_tones(utf8_peek(s + 3), 1);
                if(n3 != 0x65 /* e */ && n3 != 0xea /* ê */ && n3 != 0x69 /* i */) {
                    return 0;
                }
                return is_syllable((const char *)(s + 3));
            }
            return is_syllable((const char *)(s + 2));
        }
        return is_syllable((const char *)(s + 1));
    }
    if(cp == 0x70) { /* p */
        if(np == 0x68 /* h */) {
            return is_syllable((const char *)(s + 2));
        }
        return is_syllable((const char *)(s + 1));
    }
    if(cp == 0x71) { /* q */
        if(np == 0x75 /* u */) {
            return is_syllable((const char *)(s + 2));
        }
        return is_syllable((const char *)(s + 1));
    }
    if(cp == 0x74) { /* t */
        if(np == 0x68 /* h */ || np == 0x72 /* r */) {
            return is_syllable((const char *)(s + 2));
        }
        return is_syllable((const char *)(s + 1));
    }
    return 0;
}
EOF

echo "Create engine.h"

cat > engine.h <<EOF
#ifndef __ENGINE_H
#define __ENGINE_H

struct repl_t {
    char * pattern;
    char * repl;
    struct repl_t * next;
};

struct engine_t {
    char * name;
    char ** patterns;
    struct engine_t * next;
};

struct engine_t * regex_engine(const char *);
int save_regex_engine(const char *, struct engine_t);
struct repl_t * repl_engine(const char *);
int save_repl_engine(const char *, struct repl_t);

#endif
EOF

echo "Create engine.c"

cat > engine.c <<EOF
#include <engine.h>
#include <util.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

struct engine_t * regex_engine(const char * filepath) {
    if (!file_exists(filepath)) {
        return NULL;
    }
    FILE * fp = fopen(filepath, "r");
    if (!fp) {
        return NULL;
    }
    char * line = NULL;
    size_t len = 0;
    int total = 0;
    struct engine_t * en = NULL;
    struct engine_t * cn = NULL;
    struct engine_t * tmp = NULL;
    while(getline(&line, &len, fp) != -1) {
        char * s = trim_copy(line, NULL);
        if(strncmp(s, "#", 1) == 0) {
            if (tmp) {
                tmp->patterns = (char **)realloc(tmp->patterns, total * sizeof(char *));
                *(tmp->patterns + total) = NULL;
                if (en == NULL) {
                    en = tmp;
                    cn = tmp;
                } else {
                    cn->next = tmp;
                    cn = tmp;
                }
                total = 0;
            }
            tmp = (struct engine_t *)malloc(sizeof(struct engine_t));
            tmp->name = strdup(s);
            tmp->patterns = NULL;
            tmp->next = NULL;
            continue;
        }
        if(strlen(s) > 0) {
            if(!tmp->patterns) {
                tmp->patterns = (char **)malloc(sizeof(char *));
            } else {
                tmp->patterns = (char **)realloc(tmp->patterns, (total + 1) * sizeof(char *));
            }
            *(tmp->patterns + total) = strdup(s);
            total++;
            continue;
        }
    }
    if (tmp) {
        tmp->patterns = (char **)realloc(tmp->patterns, total * sizeof(char *));
        *(tmp->patterns + total) = NULL;
        if (en == NULL) {
            en = tmp;
            cn = tmp;
        } else {
            cn->next = tmp;
            cn = tmp;
        }
        total = 0;
        tmp = NULL;
    }
    fclose(fp);
    if(line) free(line);
    return en;
}

int save_regex_engine(const char * filepath, struct engine_t engine) {
    FILE * fp = fopen(filepath, "w");
    if(!fp) {
        return (1);
    }
    struct engine_t * it = &engine;
    for(; it != NULL; it = it->next) {
        fprintf(fp, "# %s\n\n", trim(it->name,"# "));
        char ** p = it->patterns;
        while(*p) {
            fprintf(fp, "%s\n", *p);
            p++;
        }
        fprintf(fp, "\n");
    }
    fclose(fp);
    return (0);
}

struct repl_t * repl_engine(const char * filepath) {
    if (!file_exists(filepath)) {
        return NULL;
    }
    FILE * fp = fopen(filepath, "r");
    if (!fp) {
        return NULL;
    }
    char * line = NULL;
    char * line1 = NULL;
    size_t len = 0;
    struct repl_t * r = NULL;
    struct repl_t * c = NULL;
    struct repl_t * tmp = NULL;
    while(getline(&line, &len, fp) != -1) {
        char * p = trim_copy(line, NULL);
        if(strlen(p) == 0) {
            continue;
        }
        if(getline(&line1, &len, fp) != -1) {
            char * q = strdup(line1);
            *(q + strlen(q) - 1) = '\0';
            if(*q == '\0') {
                q = strdup(" \\\\1 ");
            }
            tmp = (struct repl_t *)malloc(sizeof(struct repl_t));
            tmp->pattern = strdup(p);
            tmp->repl = q;
            tmp->next = NULL;
            if(r == NULL) {
                r = tmp;
                c = tmp;
            } else {
                c->next = tmp;
                c = tmp;
            }
        }
    }
    fclose(fp);
    if(line) free(line);
    if(line1) free(line1);
    return r;
}

int save_repl_engine(const char * filepath, struct repl_t repl) {
    FILE * fp = fopen(filepath, "w");
    if(!fp) {
        return (1);
    }
    struct repl_t * it = &repl;
    for(;it != NULL; it = it->next) {
        if(strcmp(it->repl, " \\\\1 ") == 0) {
            fprintf(fp, "%s\n\n\n", it->pattern);
        } else {
            fprintf(fp, "%s\n%s\n\n", it->pattern, it->repl);
        }
    }
    fclose(fp);
    return (0);
}
EOF

echo -e "Create '\033[0;32mMakefile\033[0m'"

cat > Makefile <<EOF
CC = gcc
CL = ld
CFLAGS = -O3 -Wall -std=gnu99 -pedantic -fPIC
LDFLAGS = -I. -lm -pthread -ldl
RM = rm -rf

WS_OBJS = $ws

OBJS = objects/graphql.o objects/engine.o objects/regexp.o objects/util.o

all: objects/ws.o demo

objects:
${NT}@mkdir -p objects

demo: objects objects/demo.o objects/ws.o \$(OBJS)
${NT}@\$(CC) objects/demo.o objects/ws.o \$(OBJS) -o \$@ \$(LDFLAGS)
${NT}@\$(RM) objects/demo.o

objects/ws.o: objects \$(WS_OBJS)
${NT}@\$(CC) -c \$(CFLAGS) ws.c -o objects/_ws.o \$(LDFLAGS)
${NT}@\$(CL) -r objects/_ws.o \$(WS_OBJS) -o \$@
${NT}@\$(RM) objects/_ws.o \$(WS_OBJS)

objects/graphql.o: objects objects/jsmn.o objects/gason.o
${NT}@\$(CL) -r objects/jsmn.o objects/gason.o -o \$@
${NT}@\$(RM) objects/jsmn.o objects/gason.o

objects/%.o: %.c
${NT}@\$(CC) -c \$(CFLAGS) \$< -o \$@ \$(LDFLAGS)

clean:
${NT}@\$(RM) objects/* demo
EOF
