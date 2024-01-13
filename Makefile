autorun: help

help:
	$(info $()  build ....... generate the static website)
	$(info $()  preview ..... start a static web server to preview the website)
	$(info $()  run ......... run the development server)
	$(info $()  uplift ...... upgrade Astro and Starlight)

build:
	astro build && touch docs/.nojekyll

preview:
	npm run preview

run:
	npm run dev

uplift:
	echo Upgrading Astro and Starlight...
	npx --yes @astrojs/upgrade
