{
  python3,
  fetchFromGitHub,
}:
python3.pkgs.callPackage (fetchFromGitHub {
  owner = "jcaesar";
  repo = "njx";
  rev = "0c171e17e912b404ddb4b67f692efddbeb54a4cf";
  hash = "sha256-V47S4wZWmI9mO9DIjXUyJv7gs4YNegfkv6lduxZVW5k=";
}) {}
