autorun:
	$(info uplift ...... upgrade Astro and Starlight)

uplift:
	echo Upgrading Astro
	npx --yes @astrojs/upgrade
