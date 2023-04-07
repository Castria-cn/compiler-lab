cc: cc.l cc.y cc.h ccutils.c
	bison -d cc.y
	flex -o cc.lex.c cc.l
	cc -o $@ cc.tab.c cc.lex.c ccutils.c
clean:
	rm -rf cc
	rm -rf cc.tab.h
	rm -rf ccutils
	rm -rf cc.lex.c
	rm -rf cc.tab.c
	rm -rf lex.yy.c
	rm -rf result.txt
