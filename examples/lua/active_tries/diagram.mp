outputtemplate := "active-%{letters}.mps";
prologues := 3;
input graph
Fmfont_ := "bchr8r";
Fefont_ := "bchr8r";
defaultfont := "bchr8r";
psize := 1.5;
string datafile;
datafile := "data." & decimal(letters);
wd := 12cm;
ht := 6cm;
fsize := fontsize defaultfont;
beginfig(1);
draw begingraph(wd, ht);
  setrange(0, 0, 40, 7);
  for x = 0 step 5 until 40:
    otick.bot(format("%g", x), x);
  endfor
  for y = 0 step 1 until 7:
    otick.lft(format("%g", y), y);
  endfor
  label.bot("Buchstabenposition", (.5wd, -2.5fsize));
  label.lft(thelabel("aktive Tries", origin) rotated 90, (-2.5fsize, .5ht));
  if letters = 0:
    label.top("alle Wortlängen kumuliert", (.5wd, ht + fsize));
  else:
    label.top("Wortlänge " & decimal(letters), (.5wd, ht + fsize));
  fi
  gdraw datafile plot image(fill fullcircle scaled 2psize);
endgraph;
endfig;
end
