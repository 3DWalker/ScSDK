#include "scutils/system/scapplication.h"
#include "scutils/system/scservice.h"
#include "scutils/text/scstringlist.h"

int main(int argc, char *argv[])
{
	argc = 2;
	std::vector<char*> args(argc);
	ScStringList argvs{ argv[0], "-e" };
	for (int i = 0; i < argc; i++)
		args[i] = argvs[i].data();

	ScService a(argc, args.data(), "Test");
	int ret = a.exec();
	FILE* fp = fopen("D:/log.txt", "w");
	fwrite(&ret, sizeof(int), 1, fp);
	fclose(fp);
	return ret;
}