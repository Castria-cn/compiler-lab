cc: cc.l cc.y cc.h ccutils.c symbol_table.c
	bison -d cc.y
	flex -o cc.lex.c cc.l
	cc -o $@ -w cc.tab.c cc.lex.c symbol_table.c ccutils.c
clean:
	rm -rf cc
	rm -rf cc.tab.h
	rm -rf ccutils
	rm -rf cc.lex.c
	rm -rf cc.tab.c
	rm -rf lex.yy.c
	rm -rf result.txt
