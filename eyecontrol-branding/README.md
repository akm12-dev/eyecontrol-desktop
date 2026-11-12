# EyeControl Desktop

Client de prise en main à distance d'**EyeControl** (AKM12), basé sur
[RustDesk](https://github.com/rustdesk/rustdesk) 1.5.1, logiciel libre sous licence **AGPL-3.0**.

Modifications apportées par AKM12 (et seulement celles-ci) :

- nom de l'application : `EyeControl` ;
- serveur intégré : `hosting.websentinelle.com` (serveur RustDesk auto-hébergé d'AKM12) et sa clé publique ;
- icônes générées depuis le logo EyeControl (`make_icons.ps1`, `icon.svg`) ;
- textes des ressources Windows (nom du produit, description, éditeur, copyright).

Tout le reste est le code de RustDesk, sans modification. Les changements du sous-module
`libs/hbb_common` sont appliqués à la compilation par `apply_branding.py`.

Compilation : workflow `.github/workflows/eyecontrol-windows.yml` (Windows x64, sans signature).

Le code source complet de chaque version publiée est ce dépôt, à l'étiquette correspondante,
conformément à l'AGPL-3.0. RustDesk est une marque de ses auteurs ; ce logiciel n'est ni édité
ni approuvé par eux.
