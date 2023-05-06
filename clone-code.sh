#!/bin/bash

SRC="/tmp/src"
DEST="`pwd`/src"

if [ ! -d "$SRC" ];
then
  echo "Create source folder ..."
  mkdir -p $SRC
fi

if [ ! -d "$SRC/mregexp" ];
then
  echo "Clone mregexp repo ..."
  cd $SRC
  git clone https://github.com/tylov-fork/mregexp --branch faster-utf8 --single-branch mregexp
fi

if [ ! -d "$SRC/regexp9" ]; then
    echo "Clone regexp9 repo ..."
    cd $SRC
    git clone https://github.com/tylov/regexp9
fi

if [ ! -d "$DEST" ];
then
  echo "Create project source folder ..."
  mkdir -p $DEST
fi

echo "Clean '$DEST' folder ..."

rm -rf $DEST/*

cd $DEST

echo "Create utf8.h header file ..."

cp -rf $SRC/mregexp/mregexp.h regexp.h
cp -rf $SRC/mregexp/mregexp.c regexp.c

cat > utf8.h <<EOF
#ifndef _UTF8_H
#define _UTF8_H

EOF

sed '1143,$d' $SRC/regexp9/utf8_tables.h | sed '1067,$d' >> utf8.h
sed '113,$d' regexp.c | sed '81,97d' | sed '1,35d' >> utf8.h
echo '#endif' >> utf8.h

sed -i 's/MRegexp/Regexp/g' regexp.h
sed -i 's/MRegexp/Regexp/g' regexp.c
sed -i 's/MREGEXP_/REGEXP_/g' regexp.h
sed -i 's/MREGEXP_/REGEXP_/g' regexp.c
sed -i 's/mregexp_/regexp_/g' regexp.h
sed -i 's/mregexp_/regexp_/g' regexp.c
sed -i 's/"mregexp\.h"/<regexp.h>/g' regexp.c

sed '40,$d' regexp.h > a.c
cat >> a.c <<EOF
typedef enum {
    REGEX_IGNORECASE,
    REGEX_DOTALL
} Reflags;

EOF
sed '1,39d' regexp.h | sed '17,$d' >> a.c
echo 'Regexp *regexp_compile(const char *re, Reflags flags);' >> a.c
sed '1,56d' regexp.h | sed '22,$d' >> a.c

sed '1,77d' regexp.h >> a.c
mv a.c regexp.h

sed '30,$d' regexp.c > a.c
echo '#include <utf8.h>' >> a.c
sed '1,30d' regexp.c | sed '68,83d' | sed '6,49d' | sed '15,16d' >> a.c
mv a.c regexp.c

sed '63,$d' regexp.c > a.c
echo '    Reflags flags;' >> a.c
sed '129,$d' regexp.c | sed '1,62d' >> a.c
cat >> a.c <<EOF
    uint32_t cp = utf8_peek(cur);
    if(node->generic.flags == REGEX_IGNORECASE) {
        return utf8_tolower(node->chr.chr) == utf8_tolower(cp);
    }
    return node->chr.chr == cp;
EOF
sed '1,129d' regexp.c >> a.c
mv a.c regexp.c

sed '798,$d' regexp.c > a.c
echo 'Regexp *regexp_compile(const char *re, Reflags flags)' >> a.c
sed '1,798d' regexp.c | sed '35,$d' >> a.c
cat >> a.c <<EOF
    for(RegexNode * p = nodes; p != NULL; p = p->generic.next) {
        p->generic.flags = flags;
    }
EOF
sed '1,832d' regexp.c >> a.c
mv a.c regexp.c

if [ ! -d "resources" ];
then
  echo "Create resources folder ..."
  mkdir -p resources
fi

echo "Clean resources folder ..."

rm -rf resources/*

echo "Create regex spliter ..."

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

echo "Create regex replace data pre processing ..."

# TODO: leave empty line to replace with first matched

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

echo "Create util.h header ..."

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
int is_syllable(const char *);
char * uniquid_spaces(char *, int);

#endif
EOF

echo "Define function implement for util headers"

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
// https://github.com/sheredom/utf8.h/blob/master/utf8.h
static uint8_t * utf8_codepoint(const uint8_t * str, uint32_t *cp) {
    *cp = utf8_peek((const char *)str);
    uint32_t n = utf8_char_width(*str);
    if(n == 0 || *cp == 0) return NULL;
    str += n;
    return (uint8_t *)str;
}
static uint8_t * utf8_cat_codepoint(uint8_t * str, uint32_t chr, size_t n) {
    if(0 == ((uint32_t)0xffffff80 & chr)) {
        if(n < 1) return NULL;
        str[0] = (uint8_t)chr;
        str += 1;
    } else if (0 == ((uint32_t)0xfffff800 & chr)) {
        if(n < 2) return NULL;
        str[0] = (uint8_t)(0xc0 | (uint8_t)((chr >> 6) & 0x1f));
        str[1] = (uint8_t)(0x80 | (uint8_t)(chr & 0x3f));
        str += 2;
    } else if (0 == ((uint32_t)0xffff0000 & chr)) {
        if(n < 3) return NULL;
        str[0] = (uint8_t)(0xe0 | (uint8_t)((chr >> 12) & 0x0f));
        str[1] = (uint8_t)(0x80 | (uint8_t)((chr >> 6) & 0x3f));
        str[2] = (uint8_t)(0x80 | (uint8_t)(chr & 0x3f));
        str += 3;
    } else {
        if(n < 4) return NULL;
        str[0] = (uint8_t)(0xf0 | (uint8_t)((chr >> 18) & 0x07));
        str[1] = (uint8_t)(0x80 | (uint8_t)((chr >> 12) & 0x3f));
        str[2] = (uint8_t)(0x80 | (uint8_t)((chr >> 6) & 0x3f));
        str[3] = (uint8_t)(0x80 | (uint8_t)(chr & 0x3f));
        str += 4;
    }
    return str;
}
static size_t utf8_codepoint_size(uint32_t chr) {
    if (0 == ((uint32_t)0xffffff80 & chr)) {
        return 1;
    } else if (0 == ((uint32_t)0xfffff800 & chr)) {
        return 2;
    } else if (0 == ((uint32_t)0xffff0000 & chr)) {
        return 3;
    } else {
        return 4;
    }
}

static char * tranform_s(char * s, int mode) {
    uint8_t * str = (uint8_t*)s;
    uint32_t cp = 0;
    uint8_t * pn = utf8_codepoint(str, &cp);
    while(cp != 0) {
        const uint32_t tranform_cp = mode ? utf8_toupper(cp) : utf8_tolower(cp);
        const size_t size = utf8_codepoint_size(tranform_cp);
        if(tranform_cp != cp) {
            utf8_cat_codepoint(str, tranform_cp, size);
        }
        str = pn;
        pn = utf8_codepoint(str, &cp);
    }
    return s;
}

char * to_lower(char * s) {
    return tranform_s(s, 0);
}
char * to_upper(char * s) {
    return tranform_s(s, 1);
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
static inline const char * utf8_at(const char * s, size_t index)
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
static inline uint32_t utf8_peek_at(const char * s, size_t index)
{
    const char * e = utf8_at(s, index);
    if(e == NULL) return 0;
    return utf8_peek(e);
}
static inline size_t utf8_strlen(const char * s) {
    size_t len = 0;
    while(*s) {
        len++;
        s = utf8_next(s);
    }
    return len;
}
int is_syllable(const char * s) {
    uint32_t cp = normal_non_tones(utf8_peek(s), 1);
    if (cp == 0x61) { /* a */
        if(utf8_strlen(s) > 3) return 0;
        const char * e = utf8_next(s);
        if(e == NULL || *e == '\0') return 1;
        uint32_t np = normal_non_tones(utf8_peek(e), 1);
        /* a, ac, ach, ai, am, an, ang, anh, ao, ap, at, au, ay. */
        if(
            np == 0x69 /* i */ || np == 0x6d /* m */ || np == 0x6f /* o */ ||
            np == 0x70 /* p */ || np == 0x74 /* t */ || np == 0x75 /* u */ ||
            np == 0x79 /* y */
        ) {
            if(*(e + utf8_char_width(*e)) != '\0') return 0;
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
        const char * e = utf8_next(s);
        if(e == NULL || *e == '\0') return 1;
        uint32_t np = normal_non_tones(utf8_peek(e), 1);
        /* ă, ăc, ăm, ăn, ăng, ăp, ăt. */
        if(
            np == 0x63 /* c */ || np == 0x6d /* m */ || np == 0x70 /* p */ ||
            np == 0x74 /* t */
        ) {
            if(*(e + utf8_char_width(*e)) != '\0') return 0;
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
        const char * e = utf8_next(s);
        if(e == NULL || *e == '\0') return 1;
        uint32_t np = normal_non_tones(utf8_peek(e), 1);
        /* â, âc, âm, ân, âng, âp, ât, âu, ây. */
        if(
            np == 0x63 /* c */ || np == 0x6d /* m */ || np == 0x70 /* p */ ||
            np == 0x74 /* t */ || np == 0x75 /* u */ || np == 0x79 /* y */
        ) {
            if(*(e + utf8_char_width(*e)) != '\0') return 0;
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
        const char * e = utf8_next(s);
        if(e == NULL || *e == '\0') return 1;
        uint32_t np = normal_non_tones(utf8_peek(e), 1);
        /* e, ec, em, en, eng, eo, ep, et. */
        if(
            np == 0x63 /* c */ || np == 0x6d /* m */ || np == 0x6f /* o */ ||
            np == 0x70 /* p */ || np == 0x74 /* t */
        ) {
            if(*(e + utf8_char_width(*e)) != '\0') return 0;
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
        const char * e = utf8_next(s);
        if(e == NULL || *e == '\0') return 1;
        uint32_t np = normal_non_tones(utf8_peek(e), 1);
        /* ê, êch, ênh, êm, ên, êp, êt, êu. */
        if(
            np == 0x6d /* m */ || np == 0x70 /* p */ || np == 0x74 /* t */ ||
            np == 0x75 /* u */
        ) {
            if(*(e + utf8_char_width(*e)) != '\0') return 0;
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
        const char * e = utf8_next(s);
        if(e == NULL || *e == '\0') return 1;
        uint32_t np = normal_non_tones(utf8_peek(e), 1);
        /* i, ich, im, in, inh, ip, it, iu. */
        /* ia, iêc, iêm, iên, iêng, iêp, iêt, iêu. */
        if(
            np == 0x6d /* m */ || np == 0x61 /* a */ || np == 0x70 /* p */ ||
            np == 0x74 /* t */ || np == 0x75 /* u */
        ) {
            if(*(e + utf8_char_width(*e)) != '\0') return 0;
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
        const char * e = utf8_next(s);
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
            if(*(e + utf8_char_width(*e)) != '\0') return 0;
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
        const char * e = utf8_next(s);
        if(e == NULL || *e == '\0') return 1;
        uint32_t np = normal_non_tones(utf8_peek(e), 1);
        /* ô, ôc, ôi, ôm, ôn, ông, ôp, ôt. */
        if(
            np == 0x63 /* c */ || np == 0x69 /* i */ || np == 0x6d /* m */ ||
            np == 0x70 /* p */ || np == 0x74 /* t */
        ) {
            if(*(e + utf8_char_width(*e)) != '\0') return 0;
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
        const char * e = utf8_next(s);
        if(e == NULL || *e == '\0') return 1;
        uint32_t np = normal_non_tones(utf8_peek(e), 1);
        /* ơ, ơi, ơm, ơn, ơp, ơt. */
        if(
            np == 0x69 /* i */ || np == 0x6d /* m */ || np == 0x6e /* n */ ||
            np == 0x70 /* p */ || np == 0x74 /* t */
        ) {
            if(*(e + utf8_char_width(*e)) != '\0') return 0;
            return 1;
        }
        return 0;
    }
    if (cp == 0x75) { /* u */
        if(utf8_strlen(s) > 4) return 0;
        const char * e = utf8_next(s);
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
        const char * e = utf8_next(s);
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
        const char * e = utf8_next(s);
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
        return is_syllable(utf8_next(s));
    }
    uint32_t np = normal_non_tones(utf8_peek(s + 1), 1);
    if(cp == 0x63) { /* c */
        if(np == 0x68 /* h */) {
            return is_syllable(s + 2);
        }
        return is_syllable(s + 1);
    }
    if(cp == 0x67) { /* g */
        if(np == 0x68 /* h */ || np == 0x69 /* i */) {
            return is_syllable(s + 2);
        }
        return is_syllable(s + 1);
    }
    if(cp == 0x6b) { /* k */
        if(np == 0x68 /* h */) {
            return is_syllable(s + 2);
        }
        return is_syllable(s + 1);
    }
    if(cp == 0x6e) { /* n */
        if(np == 0x67 /* g */ || np == 0x68 /* h */) {
            if(np == 0x67 /* g */ && (utf8_peek(s + 2) == 0x68 /* h */ || utf8_peek(s + 2) == 0x48 /* H */)) {
                if(*(s + 3) == '\0') return 1;
                uint32_t n3 = normal_non_tones(utf8_peek(s + 3), 1);
                if(n3 != 0x65 /* e */ && n3 != 0xea /* ê */ && n3 != 0x69 /* i */) {
                    return 0;
                }
                return is_syllable(s + 3);
            }
            return is_syllable(s + 2);
        }
        return is_syllable(s + 1);
    }
    if(cp == 0x70) { /* p */
        if(np == 0x68 /* h */) {
            return is_syllable(s + 2);
        }
        return is_syllable(s + 1);
    }
    if(cp == 0x71) { /* q */
        if(np == 0x75 /* u */) {
            return is_syllable(s + 2);
        }
        return is_syllable(s + 1);
    }
    if(cp == 0x74) { /* t */
        if(np == 0x68 /* h */ || np == 0x72 /* r */) {
            return is_syllable(s + 2);
        }
        return is_syllable(s + 1);
    }
    return 0;
}
// https://stackoverflow.com/a/16790505
char * uniquid_spaces(char *str, int keep_new_line) {
    char *from, *to;
    int spc = 0;
    to = from = str;
    while(1){
        if(spc && isspace(*from) && isspace(to[-1])) {
            if(keep_new_line) {
                if(*from == '\n' || to[-1] == '\n') {
                    *from = '\n';
                }
            } else {
                to[-1] = ' ';
            }
            ++from;
        } else {
            spc = isspace(*from);
            *to++ = *from++;
            if(!to[-1])break;
        }
    }
    return str;
}
EOF

echo "Create function to load lexer ..."

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
void save_regexp_engine(const char *, struct engine_t *);
struct repl_t * repl_engine(const char *);
void save_repl_engine(const char *, struct repl_t *);

#endif
EOF

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
void save_regexp_engine(const char * filepath, struct engine_t * engine) {
    FILE * fp = fopen(filepath, "w");
    if(!fp) return;
    struct engine_t * it = engine;
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
void save_repl_engine(const char * filepath, struct repl_t * repl) {
    FILE * fp = fopen(filepath, "w");
    if(!fp) return;
    struct repl_t * it = repl;
    for(;it != NULL; it = it->next) {
        fprintf(fp, "%s\n%s\n\n", it->pattern, (strcmp(it->repl, " \\\\1 ") == 0 ? "" : it->repl));
    }
    fclose(fp);
}
EOF

echo "Create test file ..."

cat > test.c <<EOF
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <util.h>
#include <engine.h>
#include <regexp.h>

int main() {
    char * s0 = strdup("Nghiên cứu Đại học King's College London và Đại học Leiceste đăng trên Tạp chí Di truyền Con người Mỹ năm 2021 cũng cho thấy");
    printf("s0=%s\n", s0);
    char * s00 = to_lower(s0);
    printf("s0=%s\n%s\n", s0,s00);
    char * s1 = strdup("H'Hen Niê là một hoa hậu và người mẫu người Việt Nam.");
    printf("s1=%s\n", s1);
    char * s11 = to_upper(s1);
    printf("s1=%s\n%s\n", s1,s11);
    printf("đồ -> %s\n", (is_syllable("đồ") ? "True" : "False"));
    printf("mi -> %s\n", (is_syllable("mi") ? "True" : "False"));
    printf("là -> %s\n", (is_syllable("là") ? "True" : "False"));
    printf("đồ -> %s\n", (is_syllable("đồ") ? "True" : "False"));
    printf("mi -> %s\n", (is_syllable("mi") ? "True" : "False"));
    printf("phá -> %s\n", (is_syllable("phá") ? "True" : "False"));
    printf("ba -> %s\n", (is_syllable("ba") ? "True" : "False"));
    printf("mi -> %s\n", (is_syllable("mi") ? "True" : "False"));
    printf("về -> %s\n", (is_syllable("về") ? "True" : "False"));
    printf("là -> %s\n", (is_syllable("là") ? "True" : "False"));
    printf("ba -> %s\n", (is_syllable("ba") ? "True" : "False"));
    printf("mi -> %s\n", (is_syllable("mi") ? "True" : "False"));
    printf("la -> %s\n", (is_syllable("la") ? "True" : "False"));
    printf("olala -> %s\n", (is_syllable("olala") ? "True" : "False"));
    printf(". -> %s\n", (is_syllable(".") ? "True" : "False"));
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
        save_regexp_engine("b.lex", engine);
    } else {
        printf("Opts\n");
    }
    struct repl_t * repl = repl_engine("resources/repl.lex");
    if(repl) {
        struct repl_t * it = repl;
        for(;it != NULL; it = it->next) {
            printf("regex_replace(/%s/,'%s')\n", it->pattern, it->repl);
        }
        save_repl_engine("a.lex", repl);
    }
    char * so = strdup("    Of course, the above function requires you to properly   terminate the string, which you currently do not.\n\nWhat the function above does   ");
    printf("so=[%s],\nsv=[%s],\nsn=[%s]\n", so, uniquid_spaces(strdup(so),0), uniquid_spaces(strdup(so),1));
    char * text = strdup("anh hoà, đang làm.. gì 134/2. anh hoà, đang làm.. gì 134/2");
    Regexp *re = regexp_compile("oà([\\\\.,:;\\\\s$])", REGEX_DOTALL);
    if (regexp_error() || re == NULL) {
        printf("Invalid regular expression: Compile failed with error %d\n",regexp_error());
        return -1;
    }
    size_t caps = regexp_captures_len(re);
    printf("Captures: %ld\n\n", caps);
    RegexpMatch m;
    char * p = text;
    while (regexp_match(re, p, &m)) {
        char * cap = (char *)calloc(m.match_end - m.match_begin + 1, sizeof(char));
        strncpy(cap, p + m.match_begin, m.match_end - m.match_begin);
        printf("Capture: %s\n", cap);
        const RegexpMatch *cap0 = regexp_capture(re, 0);
        if(cap0) {
            char * capture = (char *)calloc(cap0->match_end - cap0->match_begin + 1, sizeof(char));
            strncpy(capture, p + cap0->match_begin, cap0->match_end - cap0->match_begin);
            printf("cap1=%s\n", capture);
        }
        p += m.match_end;
    }
    regexp_free(re);
    return 0;
}
EOF

echo "Create Makefile ..."

NEWLINE=$'\n'
NEWTAB=$'\t'

cat > Makefile <<EOF
CC = gcc
CL = ld
CFLAGS = -O3 -Wall -std=gnu99 -pedantic -fPIC
LDFLAGS = -I. -lm -pthread -ldl
RM = rm -rf

SRCS = engine.c util.c
OBJS = \$(SRCS:.c=.o)
OBJS := \$(addprefix objects/,\$(OBJS))
OBJS += objects/regex.o

all: objects \$(OBJS)

test: objects objects/test.o \$(OBJS)
${NEWTAB}@\$(CC) \$(CFLAGS) objects/test.o \$(OBJS) -o \$@ \$(LDFLAGS)

objects:
${NEWTAB}@mkdir -p objects

objects/test.o: test.c
${NEWTAB}@\$(CC) -c \$(CFLAGS) \$< -o \$@ \$(LDFLAGS)

objects/%.o: %.c
${NEWTAB}@\$(CC) -c \$(CFLAGS) \$< -o \$@ \$(LDFLAGS)

objects/regex.o: regexp.c
${NEWTAB}@\$(CC) -c \$(CFLAGS) \$< -o \$@ \$(LDFLAGS)

clean:
${NEWTAB}\$(RM) objects/*
EOF

echo "Make test"

make test

echo "Done !"
exit
