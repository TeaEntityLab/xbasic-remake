/* mkxbvar.c - Create xbvar.bat which contains the correct settings for
 *	       the environment variables needed by XBasic and tools.
 */
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <windows.h>

#ifndef	__cplusplus
typedef int bool;
const int false = 0;
const int true = 1;
#endif

/** Maximum length of a command-line argument. */
#define	MAX_ARG_SIZE			(256)

/** Abend the program with an error-message.
 * @param fmt	Printf-like error-message.
 */
static void error(char *fmt, ...)
{
	char	szBuf[256 + 1];
	va_list	args;

	va_start(args, fmt);
	vsprintf(szBuf, fmt, args);
	va_end(args);
	MessageBox(NULL, szBuf, "Alert",
		MB_APPLMODAL | MB_ICONEXCLAMATION | MB_OK);
	exit(1);
}
/** Add a command-line argument to an array of command-line arguments.
 * @param prgszArg	The array of command-line arguments.
 * @param pcArg		The number of elements in the array.
 * @param szArg		The new command-line argument.
 */
static void addArg(char ***prgszArg, int *pcArg, const char *szArg)
{
	*prgszArg = realloc(*prgszArg, sizeof(char *) * (*pcArg + 1));
	if (*prgszArg == NULL)
	{
		error("Out of memory");
	}
	(*prgszArg)[*pcArg] = strdup(szArg);
	++(*pcArg);
}
/** Convert a command-line into an array of command-line arguments.
 * @param szCmdLine	The command-line.
 * @param prgszArg	The array of command-line arguments.
 * @param pcArg		The number of elements in the array.
 */
static void scanCommandLine(char *szCmdLine, char ***prgszArg, int *pcArg)
{
	char	**rgszArg = NULL;
	int	cArg = 0;
	char	*s;
	char	szBuf[MAX_ARG_SIZE + 1];
	int	cBuf;
	bool	fQuote = false;

	cBuf = GetModuleFileName(NULL, szBuf, MAX_ARG_SIZE);
	szBuf[cBuf] = '\0';
	addArg(&rgszArg, &cArg, szBuf);

	cBuf = 0;
	for (s = szCmdLine; *s != '\0'; ++s)
	{
		if ((*s == ' ' || *s == '\t') && !fQuote)
		{
			if (cBuf > 0)
			{
				szBuf[cBuf] = '\0';
				addArg(&rgszArg, &cArg, szBuf);
				cBuf = 0;
			}
		}
		else
		{
			if (cBuf >= MAX_ARG_SIZE)
			{
				error("Command-line argument too long");
			}
			if (*s == '\"')
				fQuote = !fQuote;
			else
				szBuf[cBuf++] = *s;
		}
	}
	if (cBuf > 0)
	{
		szBuf[cBuf] = '\0';
		addArg(&rgszArg, &cArg, szBuf);
		cBuf = 0;
	}
	*prgszArg = rgszArg;
	*pcArg = cArg;
}
static void getShortName(char *szDir, char *szDirShort)
{
	int	cBuf;

	if (szDir == NULL || *szDir == '\0')
	{
		*szDirShort = '\0';
		return;
	}
	cBuf = GetShortPathName(szDir, szDirShort, _MAX_PATH);
	if (cBuf < 0)
	{
		error("GetShortPathName(%s) failed: %ld\n", szDir,
			GetLastError());
	}
	szDirShort[cBuf] = '\0';
}
/** Write a batch-file containing the environment-variables needed by XBasic.
 */
static void writeXBVars(char *szXBDir, char *szGNUUtilDir)
{
	FILE	*f;
	char	szXBDirShort[_MAX_PATH + 1];
	char	szGNUUtilDirShort[_MAX_PATH + 1];
	char	szBuf[_MAX_PATH + 1];

	/* Filenames containing spaces give trouble when used in environment-
	 * variables, so use the short filename version. */
	getShortName(szXBDir, szXBDirShort);
	getShortName(szGNUUtilDir, szGNUUtilDirShort);

	if (GetWindowsDirectory(szBuf, _MAX_PATH) == 0)
	{
		error("GetWindowsDirectory() failed: %ld", GetLastError());
	}
	strcat(szBuf, "\\xbvars.bat");
	f = fopen(szBuf, "w");
	if (f == NULL)
	{
		error("Cannot open '%s'", szBuf);
	}
	fprintf(f, "@ECHO OFF\n");
	fprintf(f, "REM This file is created automatically during installation of XBasic\n");
	fprintf(f, "REM DON'T MODIFY BY HAND!\n");
	fprintf(f, "\n");
	fprintf(f, "REM XBDIR=%s\n", szXBDir);
	fprintf(f, "REM GNUDIR=%s\n", szGNUUtilDir);
	fprintf(f, "\n");
	fprintf(f, "SET XBDIR=%s\n", szXBDir);
	if (*szXBDirShort != '\0' || *szGNUUtilDirShort != '\0')
	{
		fprintf(f, "SET PATH=");
		if (*szXBDirShort != '\0')
			fprintf(f, "%s\\bin;", szXBDirShort);
		if (*szGNUUtilDirShort != '\0')
			fprintf(f, "%s\\bin;", szGNUUtilDirShort);
		fprintf(f, "%%PATH%%\n");
		if (*szXBDirShort != '\0')
		{
			fprintf(f, "SET LIB=%s\\lib;%%LIB%%\n", szXBDirShort);
			fprintf(f, "SET INCLUDE=%s\\include;%%INCLUDE%%\n",
				szXBDirShort);
		}
	}
	fclose(f);
}
static int readXBVars(char *szXBDir, char *szGNUUtilDir)
{
	FILE	*f;
	char	szBuf[_MAX_PATH + 1];
	int	n;

#if 1
	if (GetWindowsDirectory(szBuf, _MAX_PATH) == 0)
	{
		error("GetWindowsDirectory() failed: %ld", GetLastError());
	}
	strcat(szBuf, "\\xbvars.bat");
#else
	strcpy(szBuf, "xbvars.bat");
#endif
	f = fopen(szBuf, "r");
	if (f == NULL)
	{
		/* xbvars.bat doesn't exist yet. */
		return (0);
	}
	szBuf[_MAX_PATH] = '\0';
	while (fgets(szBuf, _MAX_PATH, f) != NULL)
	{
		n = strlen(szBuf);
		if (szBuf[n - 1] == '\n')
			/* Remove trailing \n. */
			szBuf[n - 1] = '\0';
		if (strncmp(szBuf, "REM XBDIR=", 10) == 0)
		{
			strcpy(szXBDir, &szBuf[10]);
		}
		else if (strncmp(szBuf, "REM GNUDIR=", 11) == 0)
		{
			strcpy(szGNUUtilDir, &szBuf[11]);
		}
	}
	fclose(f);
	return (0);
}
static void usage(void)
{
	error("Usage: mkxbvar <variable> <directory>");
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
	LPSTR lpCmdLine, int nShowCmd)
{
	char	**argv;
	int	argc;
	/** Directory into which XBasic is installed. */
	char	szXBDir[_MAX_PATH + 1] = "";
	/** Directory into which the GNU utilities are installed. */
	char	szGNUUtilDir[_MAX_PATH + 1] = "";

	scanCommandLine(lpCmdLine, &argv, &argc);
	if (argc != 3)
		usage();
	readXBVars(szXBDir, szGNUUtilDir);
	if (strcmp(argv[1], "XBDIR") == 0)
		strcpy(szXBDir, argv[2]);
	else if (strcmp(argv[1], "GNUDIR") == 0)
		strcpy(szGNUUtilDir, argv[2]);
	else
		usage();
	writeXBVars(szXBDir, szGNUUtilDir);
	return (0);
}
