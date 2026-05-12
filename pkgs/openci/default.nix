{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  gitMinimal,
  gh,
  importNpmLock,
  makeWrapper,
  nodejs_24,
}:

buildNpmPackage (finalAttrs: {
  pname = "openci";
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "minghinmatthewlam";
    repo = "openci";
    rev = "v${finalAttrs.version}";
    hash = "sha256-lcbngSKU5B261ZIHtCyG2Tt819LfWKQBohkgp6IziIw=";
  };

  npmDeps = importNpmLock { npmRoot = finalAttrs.src; };
  npmConfigHook = importNpmLock.npmConfigHook;

  nodejs = nodejs_24;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram "$out/bin/openci" \
      --prefix PATH : ${
        lib.makeBinPath [
          gitMinimal
          gh
        ]
      }
  '';

  meta = {
    description = "Install GitHub Actions workflows from any repo";
    homepage = "https://github.com/minghinmatthewlam/openci";
    license = lib.licenses.asl20;
    maintainers = [ lib.maintainers.MH0386 ];
    mainProgram = "openci";
  };
})
