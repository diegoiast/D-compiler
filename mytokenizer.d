#! /home/elcuco/src/d/dmd/linux/bin/dmd -run

import std.stdio;
import std.stream;
import std.ctype;

enum TokenTypes {
	LEFT_PAREN,			// (
	RIGHT_PAREN,			// )
	LEFT_BRACKET,			// [
	RIGHT_BRACKET,			// ]
	ADD_SIGN,			// +
	SUB_SIGN,			// -
	DIVIDE_SIGN,			// /
	MULTIPLY_SIGN,			// *
	MULTIPLY_EQUAL_SIGN,		// *=
	ADD_EQUAL_SIGN,			// +=
	SUB_EQUAL_SIGN,			// -=
	DIVIDE_EQUAL_SIGN,		// /=
	EQUAL_EQUAL_SIGN,		// ==
	EQUAL_SIGN,			// =
	INCREMENT_SIGN,			// ++
	DECREMENT_SIGN,			// --
	SINGLE_LINE_COMMENT,		// //
	MULTI_LINE_COMMENT_START,	// /*
	MULTI_LINE_COMMENT_END,		// */
	POINTER_SIGN,			// ->
	SEMICOLON,			// ;
	DOT, 				// .
	COMA,				// ,
	GREAT_SIGN, 			// >
	GREAT_EQUAL_SIGN,		// <=
	SHIFT_RIGHT_SIGN,		// >>
	SMALLER_SIGN, 			// <
	SMALLER_EQUAL_SIGN,		// <=
	SHIFT_LEFT_SIGN,		// <<
	NOT_EQUAL_SIGN,			// !=
	NOT_SIGN,			// !
	LOGICAL_AND_SIGN,		// &
	BIT_AND_SIGN,			// &&
	LOGICAL_OR_SIGN,		// |
	BIT_OR_SIGN,			// ||
	
	IDENTIFIER,
	CONST,
	STRING_CONST,
	CHAR_CONST,
	
	// error tokens
	ERROR = -1,
	ERROR_STRING = -2,
	ERROR_CHAR = -3
}

struct TokenItem
{
	TokenTypes type;
	string value;
}

class MyTokenizer
{
public:
	this()
	{
		position	= 0;
		data		= "";
		fileName	= "";
	}
	
	this( string fileToRead )
	{
		loadFile( fileToRead );
	}
	
	void loadFile( string fileToRead )
	{
		position = 0;
		fileName = fileToRead;
		data = cast(char[])std.file.read( fileName );
	}
	
	char getChar()
	{
		// todo should we throw an exception?
		if (EndOfInput)
			return 0;
			
		position =  position + 1;
		return data[ position-1 ];
	}
	
	void skipWhiteSpace()
	{
		char c = data[position];
		if (EndOfInput())
			return;
			
		while ( (c==' ') || (c=='\t') || (c=='\n') || (c=='\r') )
		{
			position = position + 1;
			if (EndOfInput())
				return;
			c = data[position];
		}
	}
	
	bool EndOfInput()
	{
		return position == data.length;
	}
		
	TokenItem getToken()
	{
		TokenItem tokenItem;
		tokenItem.type  = TokenTypes.ERROR;
		tokenItem.value = "";
		
		skipWhiteSpace();
		// no need to process - we are at the end of file
		if (EndOfInput())
			goto RETURN;
			
		char c = getChar();
		
		// calling isdigit() will conflict with stream.isdigit()
		if (std.ctype.isdigit(c))
			return ScanForConstant();
			
		if ( (isalnum(c)) || (c=='_') )
			return ScanForIdentifier();
		
		switch (c)
		{
			case '+':
				return ScanForAddOrIncrement();
			case '-':
				return ScanForSubOrDecrement();
			case '*':
				return ScanForMultiplyKeyword();
			case '/':
				return ScanForCommentOrDevide();
			case '=':
				return ScanForEqualOrAssign();
			case '"':
				return ScanForString();
			case '\'':
				return ScanForChar();
			case '<':
				return ScanForLessKeyword();
			case '>':
				return ScanForGreatKeyword();
			case '!':
				return ScanForNotKeyword();
			case '&':
				return ScanForAndKeyword();
			case '|':
				return ScanForOrKeyword();
			
			case '{':
				tokenItem.type = TokenTypes.LEFT_BRACKET;
				break;
			case '}':
				tokenItem.type = TokenTypes.RIGHT_BRACKET;
				break;
			case '(':
				tokenItem.type = TokenTypes.LEFT_PAREN;
				break;
			case ')':
				tokenItem.type = TokenTypes.RIGHT_PAREN;
				break;
			case '.':
				tokenItem.type = TokenTypes.DOT;
				break;
			case ',':
				tokenItem.type = TokenTypes.COMA;
				break;
			case ';':
				tokenItem.type = TokenTypes.SEMICOLON;
				break;
			default:
				tokenItem.type = TokenTypes.ERROR;
				break;
		}
		
		tokenItem.value = [c];
		
	RETURN:
		return tokenItem;
	}

	// conatants must start with a alpha-numeric char
	TokenItem ScanForIdentifier()
	{
		TokenItem tokenItem;
		char c = data[position-1];
		tokenItem.value = "";
		
		while ( position <= data.length )
		{
			if ( (c!='_' ) && (!isalnum(c)) )
				break;
			tokenItem.value ~= c;
			c = getChar();
		}
		tokenItem.type  = TokenTypes.IDENTIFIER;
		
		// need to un-get the last char
		position--;
		return tokenItem;
	}
	
	// constants can start with a digit, currently only decimal numbers
	// TODO
	//	0x[0..f] HEX numbers
	//	0[0..7] Octal numbers
	//	[0..9]e(+-)[0..9] float numbers
	TokenItem ScanForConstant()
	{
		TokenItem tokenItem;
		char c = data[position-1];
		tokenItem.value = "";
		
		while ( position <= data.length )
		{
			if (!std.ctype.isdigit(c))
				break;
			tokenItem.value ~= c;
			c = getChar();
		}
		tokenItem.type  = TokenTypes.CONST;
		
		// need to un-get the last char
		if (!EndOfInput)
			position--;
		return tokenItem;
	}
	
	TokenItem ScanForCommentOrDevide()
	{
		TokenItem tokenItem;
		char c = data[position];
		
		switch (c)
		{
			case '/':
				position ++;
				tokenItem.value = "//";
				tokenItem.type  = TokenTypes.SINGLE_LINE_COMMENT;
				break;
			case '*':
				position ++;
				tokenItem.value = "/*";
				tokenItem.type  = TokenTypes.MULTI_LINE_COMMENT_START;
				break;
			case '=':
				position ++;
				tokenItem.value = "/=";
				tokenItem.type  = TokenTypes.DIVIDE_EQUAL_SIGN;
				break;
			default:
				tokenItem.value = "/";
				tokenItem.type  = TokenTypes.DIVIDE_SIGN;
		}
		
		return tokenItem;
	}
	
	TokenItem ScanForAddOrIncrement()
	{
		TokenItem tokenItem;
		char c = data[position];
		
		switch (c)
		{
			case '+':
				position ++;
				tokenItem.value = "++";
				tokenItem.type  = TokenTypes.INCREMENT_SIGN;
				break;
			case '=':
				position ++;
				tokenItem.value = "+=";
				tokenItem.type  = TokenTypes.ADD_EQUAL_SIGN;
				break;
			default:
				tokenItem.value = "+";
				tokenItem.type  = TokenTypes.ADD_SIGN;
		}
		
		return tokenItem;
	}

	TokenItem ScanForSubOrDecrement()
	{
		TokenItem tokenItem;
		char c = data[position];
		
		switch (c)
		{
			case '-':
				position ++;
				tokenItem.value = "--";
				tokenItem.type  = TokenTypes.DECREMENT_SIGN;
				break;
			case '=':
				position ++;
				tokenItem.value = "-=";
				tokenItem.type  = TokenTypes.SUB_EQUAL_SIGN;
				break;
			case '>':
				position ++;
				tokenItem.value = "->";
				tokenItem.type  = TokenTypes.POINTER_SIGN;
				break;
			default:
				tokenItem.value = "-";
				tokenItem.type  = TokenTypes.SUB_SIGN;
		}
		
		return tokenItem;
	}

	TokenItem ScanForMultiplyKeyword()
	{
		TokenItem tokenItem;
		char c = data[position];
		
		switch (c)
		{
			case '=':
				position ++;
				tokenItem.value = "==";
				tokenItem.type  = TokenTypes.MULTIPLY_EQUAL_SIGN;
				break;
			case '/':
				position ++;
				tokenItem.value = "*/";
				tokenItem.type  = TokenTypes.MULTI_LINE_COMMENT_END;
				break;
			default:
				tokenItem.value = "*";
				tokenItem.type  = TokenTypes.MULTIPLY_SIGN;
		}
		
		return tokenItem;
	}

	TokenItem ScanForEqualOrAssign()
	{
		TokenItem tokenItem;
		char c = data[position];
		
		switch (c)
		{
			case '=':
				position ++;
				tokenItem.value = "==";
				tokenItem.type  = TokenTypes.EQUAL_EQUAL_SIGN;
				break;
			default:
				tokenItem.value = "=";
				tokenItem.type  = TokenTypes.EQUAL_SIGN;
		}
		
		return tokenItem;
	}
	
	TokenItem ScanForLessKeyword()
	{
		TokenItem tokenItem;
		char c = data[position];
		
		switch (c)
		{
			case '<':
				position ++;
				tokenItem.value = "<<";
				tokenItem.type  = TokenTypes.SHIFT_LEFT_SIGN;
				break;
			case '=':
				position ++;
				tokenItem.value = "<=";
				tokenItem.type  = TokenTypes.SMALLER_EQUAL_SIGN;
				break;
				
			default:
				tokenItem.value = "<";
				tokenItem.type  = TokenTypes.SMALLER_SIGN;
		}
		
		return tokenItem;
	}
	
	TokenItem ScanForGreatKeyword()
	{
		TokenItem tokenItem;
		char c = data[position];
		
		switch (c)
		{
			case '>':
				position ++;
				tokenItem.value = ">>";
				tokenItem.type  = TokenTypes.SHIFT_RIGHT_SIGN;
				break;
			case '=':
				position ++;
				tokenItem.value = ">=";
				tokenItem.type  = TokenTypes.GREAT_EQUAL_SIGN;
				break;
				
			default:
				tokenItem.value = ">";
				tokenItem.type  = TokenTypes.GREAT_SIGN;
		}
		
		return tokenItem;
	}
	
	TokenItem ScanForNotKeyword()
	{
		TokenItem tokenItem;
		char c = data[position];
		
		switch (c)
		{
			case '=':
				position ++;
				tokenItem.value = "!=";
				tokenItem.type  = TokenTypes.NOT_EQUAL_SIGN;
				break;
				
			default:
				tokenItem.value = "!";
				tokenItem.type  = TokenTypes.NOT_SIGN;
		}
		
		return tokenItem;
	}
	
	TokenItem ScanForAndKeyword()
	{
		TokenItem tokenItem;
		char c = data[position];
		
		switch (c)
		{
			case '&':
				position ++;
				tokenItem.value = "&&";
				tokenItem.type  = TokenTypes.BIT_AND_SIGN;
				break;
				
			default:
				tokenItem.value = "&";
				tokenItem.type  = TokenTypes.LOGICAL_AND_SIGN;
		}
		
		return tokenItem;
	}
	
	TokenItem ScanForOrKeyword()
	{
		TokenItem tokenItem;
		char c = data[position];
		
		switch (c)
		{
			case '|':
				position ++;
				tokenItem.value = "||";
				tokenItem.type  = TokenTypes.BIT_OR_SIGN;
				break;
				
			default:
				tokenItem.value = "|";
				tokenItem.type  = TokenTypes.LOGICAL_OR_SIGN;
		}
		
		return tokenItem;
	}
	
	// TODO this is ugly code - re-write it!
	TokenItem ScanForString()
	{
		TokenItem tokenItem;
		tokenItem.value = ['"'];
		tokenItem.type  = TokenTypes.STRING_CONST;
		char c = data[position];
		
		while ( (c = data[position]) != '"' )
		{
			if ( c== '\\' )
			{
				tokenItem.value ~= c;
				position++;
				if (EndOfInput)	// this is an invalid token!
				{
					tokenItem.type  = TokenTypes.ERROR_STRING;
					break;	// kill the while loop
				}
				c = data[position];
				tokenItem.value ~= c;
			}	
			else if  (c == '\n')
			{
				tokenItem.type  = TokenTypes.ERROR_STRING;
				break;		// kill the while loop
			}
			else
				tokenItem.value ~= c;
			position ++;
			if (EndOfInput)
				break;
		}
		
		if (c == '"')
		{
			tokenItem.value ~= c;
			position++;
		}
		return tokenItem;
	}
	
	// TODO this is ugly code - re-write it!
	TokenItem ScanForChar()
	{
		TokenItem tokenItem;
		tokenItem.value = ['\''];
		tokenItem.type  = TokenTypes.CHAR_CONST;
		if (EndOfInput)
		{
			tokenItem.type = TokenTypes.ERROR_CHAR;
			goto CLEAN_EXIT;
		}
		
		char c = getChar();
		tokenItem.value ~= c;
		if (EndOfInput)
		{
			tokenItem.type = TokenTypes.ERROR_CHAR;
			goto CLEAN_EXIT;
		}
		
		if (c == '\\')
		{
			c = getChar();
			tokenItem.value ~= c;
			if (EndOfInput)
			{
				tokenItem.type = TokenTypes.ERROR_CHAR;
				goto CLEAN_EXIT;
			}
		}
		c = getChar();
		tokenItem.value ~= c;
			
		if (c!='\'')
			tokenItem.type = TokenTypes.ERROR_CHAR;
	CLEAN_EXIT:
		return tokenItem;
	}
	
private:
	char[]	data;
	int	position;
	string	fileName;
}

class MyLexer
{
public:
	this()
	{
		tokenizer = null;
	}
	
	this( string fileToRead )
	{
		tokenizer = new MyTokenizer( fileToRead );
	}
	
	this( MyTokenizer t )
	{
		tokenizer = t;
	}
	
	void parse()
	{
		int tokensCount = 0;
		
		while ( !tokenizer.EndOfInput() )
		{
			tokensCount++;
			TokenItem token = tokenizer.getToken();
			printf( "Token number %5d [%2d]: %.*s\n", tokensCount, token.type, token.value );
		}
		
		printf( "Found %d tokens.\n", tokensCount );
	}
private:
	MyTokenizer tokenizer;
}


void main(string[] args)
{
	MyTokenizer t = new MyTokenizer( "tests/test1.d" );
	MyLexer     l = new MyLexer( t );
//	MyLexer     l = new MyLexer( "mytokenizer.d" );
	
	l.parse();
}
