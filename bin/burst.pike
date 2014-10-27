/*
 *  Bursts an RFC 934 Digest into individual files.
 *  
 *  Usage:  burst.pike digest_file outputbasename
 *
 */

int main(int argc, array argv)
{
  if(argc < 3) 
  {
    exit(1, "usage: burst digest_file output_basename \n");
  }

  Stdio.File f = Stdio.File(argv[1], "r");
  string basename = argv[2];

  object burster = Mail.RFC934Digest();

  burster->burst(f, writemsg, basename);

  return 0;
}

int writemsg(string m, int num, string basename)
{
  string msgf = sprintf(basename + ".%03d", num);
  Stdio.write_file(msgf, m);
  werror("wrote " + msgf + "\n");
  return 0;
}
