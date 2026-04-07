# Misi user account for carrier-tc1
{ config, lib, pkgs, ... }: {
  users.groups.misi = {};
  users.users.misi = {
    isNormalUser = true;
    group = "misi";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    hashedPassword = "$6$Lu6oX0wPfUJRGYaE$vOo9gSwwJ4Fz8chQoYmQiwsKvMGY9ofKZig4Wb8FNHwzM2SLWczITxuEbgYpsBl2wBSzvTVB9D.Dw021DjiHi1";
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBADa7F/4YNEynreqlbcY8sig9o2hwtK485aWXRH3Hj2RDbfH+bSZTHeJqqOr1Dg0XHkMNJrJJJqyomlWRAMrqHy+aQH3htMFpf4+iVsyL6XvpQistqfUOeY+JvzCGR+16GmfIvWp3kugoyx85ViEWMlfXjhlJG64bb3v7aHSY0KnwTwzDg== kitsailer@kitsail"
    ];
  };
}
