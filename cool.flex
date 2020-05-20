/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
;
int temp=0;		

%}

/*
 * Define names for regular expressions here.//Definiranje regularnih izraza
 */

INC_CLAS			(?i:class)
INC_ELSE		        (?i:else)
INC_FI			        (?i:fi)	
INC_IF           		(?i:if)
INC_INHERITS		        (?i:inherits)
INC_IN	  		        (?i:in)
INC_POOL		        (?i:pool)
INC_LET			        (?i:let)
INC_LOOP			(?i:loop)
INC_THEN			(?i:then)
INC_WHILE			(?i:while)
INC_CASE			(?i:case)
INC_ESAC			(?i:esac)
INC_OF			        (?i:of)
INC_ISVOID		        (?i:isvoid)
FI      [Ff][Ii]
IF      [Ii][Ff] 
LETTER		[a-zA-Z]
BROJ		[0-9]
FALS		(f)(?i:alse)
TRUE		(t)(?i:rue)
TYPEID		[A-Z][_a-zA-Z0-9]*
OBJTID	        [a-z][_a-zA-Z0-9]*
NEWL	        [\n]
BIJELIZN  	[ \t\r\f\v]+
LINE_COMM	"--"
CHAR		"+"|"-"|"*"|"/"|"~"|"<"|"="|"("|")"|"{"|"}"|";"|":"|"."|","|"@"
NE_NEW_LINE	[^\n]
INT_CONST	{BROJ}+
INC_DARROW		        =>
INC_ASSIGN		        <-
INC_LE                          <=
KOMM	                        \"

		
%x COMMENT STRING ESCAPE
%%
 /*
  *  Operatori s vise izraza
  */

"*)"		{ cool_yylval.error_msg = "Unmatched *)";
			  return (ESCAPE);
			}

"(*"		{ temp++;
			  BEGIN(COMMENT);
			}

<COMMENT>{NEWL} 	{ curr_lineno++; }
<COMMENT>"(*"		{temp++;}
<COMMENT>"*)"	        {
				temp--;
				if(temp==0){
					BEGIN(INITIAL);
					   }
				else if(temp<0){
					cool_yylval.error_msg = "Unmatched *)";
					BEGIN(INITIAL);
					
				           }
			}
<COMMENT>{NE_NEW_LINE}	;



<COMMENT><<EOF>>	{
				BEGIN(INITIAL);
				if(temp>0){
					cool_yylval.error_msg = "EOF in comment.";
					return ESCAPE;
				           }
			}

{LINE_COMM}{NE_NEW_LINE}*	;


{KOMM}			{
				BEGIN(STRING);
				string_buf_ptr = string_buf;
			}    

<STRING>{KOMM}	       {
				if(string_buf_ptr - string_buf > MAX_STR_CONST-1){
					cool_yylval.error_msg = "String constant too long";
					BEGIN(ESCAPE);
					return ESCAPE;
				}
				*string_buf_ptr = '\0';
				cool_yylval.symbol = stringtable.add_string(string_buf);
				BEGIN(INITIAL);
				return STR_CONST;
			}


<STRING>{NEWL}		{
    			  curr_lineno++;
    			  BEGIN(INITIAL);
    			  cool_yylval.error_msg = "Unterminated string constant";
    			  return (ESCAPE);
			    }
		    
<STRING>\0	{ BEGIN(ESCAPE);
			  cool_yylval.error_msg = "String contains null character";
			  return (ESCAPE);
			  
			}
			
<STRING><<EOF>>	{
				cool_yylval.error_msg = "EOF in string constant";
				BEGIN(INITIAL);
				return ESCAPE;
			    }

<STRING>\\\0	  	{ BEGIN(ESCAPE);
                    	  cool_yylval.error_msg = "String contains escaped null character.";
                    	  return (ESCAPE);
                	}

<STRING>"\\n"		{ curr_lineno++;
			  *string_buf_ptr++ = '\n';
			}
<STRING>"\\t"		*string_buf_ptr++ = '\t';
<STRING>"\\b"		*string_buf_ptr++ = '\b';
<STRING>"\\f"		*string_buf_ptr++ = '\f';
                    

<STRING>"\\"[^\0]	*string_buf_ptr++ = yytext[1];
<STRING>.		*string_buf_ptr++ = *yytext;


<ESCAPE>{KOMM}         	{ BEGIN(INITIAL); }
<ESCAPE>.               ;
<ESCAPE>{NEWL}          { BEGIN(INITIAL); }




{INC_CLAS}			{ return 258; }
{INC_ELSE}			{ return ELSE;}
{INC_FI}			{ return 260; }
{INC_IF}			{ return IF;  }
{INC_INHERITS}		        { return 263; }
{INC_IN}			{ return IN;  }
{INC_POOL}		        { return 266; }
{INC_LET}			{ return LET; }
{INC_LOOP}			{ return 265; }
{INC_THEN}			{ return THEN;}
{INC_WHILE}			{ return 268; }
{INC_CASE}			{ return CASE;}
{INC_ESAC}			{ return 270; }
{INC_OF}			{ return OF;  }
{INC_ISVOID}		        { return ISVOID;}
{INC_ASSIGN}		        { return 280; }
{INC_LE}			{ return LE;  }
{BIJELIZN}		;
{CHAR} 		 { return int(yytext[0]); }

{TRUE}			{ cool_yylval.boolean = true;
                  return BOOL_CONST;
                }
{FALS}			{ cool_yylval.boolean = false;
                  return BOOL_CONST;
                }

{BROJ}+		{ cool_yylval.symbol = inttable.add_string(yytext);
                  return INT_CONST;
                }
{TYPEID}		{ cool_yylval.symbol = idtable.add_string(yytext);
                  return TYPEID;
                }

{OBJTID}		{ cool_yylval.symbol = idtable.add_string(yytext);
                  return OBJECTID;
                }
{DARROW}    	 { return  272;; }

{NEWL}		{ curr_lineno++; }

.			{ cool_yylval.error_msg = yytext;
			  return (ERROR);
			}
%%