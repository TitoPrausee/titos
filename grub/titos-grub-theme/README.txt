titOS GRUB Theme
================
Dunkles, elegantes GRUB-Theme mit titOS-Branding (Lila/Cyan).
Dark elegant GRUB theme with titOS branding (purple/cyan).

Installation (erledigt durch setup/branding.sh / handled by branding.sh):
  sudo cp -r . /boot/grub/themes/titos/
  GRUB_THEME="/boot/grub/themes/titos/theme.txt" in /etc/default/grub
  sudo grub-mkconfig -o /boot/grub/grub.cfg

Hinweis: Pixmap-Assets (select_*, slider_*) sind optional; GRUB fällt auf
Standard-Styling zurück wenn sie fehlen. / Pixmap assets optional; GRUB
falls back to default styling if absent.
