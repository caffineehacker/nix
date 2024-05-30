{ lib
, fetchFromGitHub
, python3Packages
}:

python3Packages.buildPythonApplication rec {
  pname = "kitchenowl";
  version = "0.5.1";

  src = fetchFromGitHub {
    owner = "TomBursch";
    repo = "kitchenowl";
    rev = "v${version}";
    hash = "sha256-8lWUFnsRnrqcZmIxw6OJ4QSsH0sSsRLM+Uwc/NpQM+c=";
  } + "/backend";

  format = "other";

  propagatedBuildInputs = with python3Packages; [
    alembic
    amqp
    annotated-types
    apispec
    appdirs
    apscheduler
    attrs
    autopep8
    bcrypt
    beautifulsoup4
    bidict
    black
    blinker
    blurhash
    celery
    certifi
    cffi
    charset-normalizer
    click
    click-didyoumean
    click-plugins
    click-repl
    flask
  ];

  buildPhase = ''
    python -O -m compileall .
  '';

  installPhase = ''
    mkdir -p "$out/src/kitchenowl"
    cp -r wsgi.ini wsgi.py entrypoint.sh manage.py manage_default_items.py upgrade_default_items.py "$out/src/kitchenowl/"
    cp -r app "$out/src/kitchenowl/app"
    cp -r templates "$out/src/kitchenowl/templates"
    cp -r migrations "$out/src/kitchenowl/migrations"
    install -Dm755 entrypoint.sh "$out/bin/kitchenowl.sh"
    wrapProgram $out/bin/kitchenowl.sh \
        --prefix PATH : ${lib.makeBinPath (with python3Packages; [ flask ])}
  '';

  meta = {
    homepage = "https://kitchenowl.org";
    description = "A smart grocery list and recipe manager";
    longDescription = ''
      KitchenOwl is a smart self-hosted grocery list and recipe manager.
      Easily add items to your shopping list before you go shopping.
      You can also create recipes and get suggestions on what you want to cook.
      Track your expenses so you know how much you've spent.
    '';
    changelog = "https://github.com/TomBursch/kitchenowl/releases/tag/v${version}";
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.linux;
  };
}