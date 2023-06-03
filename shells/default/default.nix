{pkgs, ...} : 
pkgs.mkShell {
  buildInputs = with pkgs; [
    nixUnstable
    deploy-rs
  ];
}