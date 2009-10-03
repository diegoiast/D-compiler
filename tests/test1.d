12 != 13;
12 = !13;
12 & 13 && 15;
12 | 13 || 15;

string s1 = "%hello\\";
char c = 'c';

var1 = 12;
second = 0;
minute = 0;
hour = 0;
hour /= 0;
12hour = 12; // this is an error

/* multiline comment
as = 12
*/

while (1)
{
	second += 1;
	if (second == 60)
	{
		second = 0;
		minute += 1;
		if (minute == 60)
		{
			minute = 0;
			hour += 1;
			if (hour == 24)
			{
				hour = 000000000;
			}
		}
	}
}
