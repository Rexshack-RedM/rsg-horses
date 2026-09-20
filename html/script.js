let Locale = {};
function t(key, fallback) {
    return (Locale && Locale[key]) || fallback || key;
}
function applyStaticLocale() {
    document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        el.textContent = t(key, el.textContent);
    });
    document.querySelectorAll('[data-i18n-title]').forEach(el => {
        const key = el.getAttribute('data-i18n-title');
        el.title = t(key, el.title);
    });
    document.querySelectorAll('[data-i18n-aria]').forEach(el => {
        const key = el.getAttribute('data-i18n-aria');
        el.setAttribute('aria-label', t(key, el.getAttribute('aria-label')));
    });
    document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
        const key = el.getAttribute('data-i18n-placeholder');
        el.placeholder = t(key, el.placeholder);
    });
}

const HorseUI = {
    isOpen: false,
    currentScreen: 'main',
    currentStableId: null,
    selectedHorse: null,
    moveHorseId: null,
    selectedMareId: null,
    screenHistory: [],
    cart: [],
    playerMoney: { cash: 0, gold: 0 },
    sortBy: 'name',
    confirmCallback: null,
    inputCallback: null,

    init() {
        this.bindEvents();
        this.setupNUICallbacks();
    },

    bindEvents() {
        document.getElementById('close-btn').addEventListener('click', () => this.close());

        document.getElementById('back-btn').addEventListener('click', () => this.goBack());

        document.getElementById('shop-container').addEventListener('wheel', (e) => {
            e.stopPropagation();
        }, { passive: false });

        const searchInput = document.getElementById('search-input');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                this.searchQuery = e.target.value.toLowerCase();
                this.renderCurrentScreen();
            });
        }

        document.querySelectorAll('.sort-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.sort-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                this.sortBy = btn.dataset.sort;
                this.renderCurrentScreen();
            });
        });

        document.getElementById('btn-clear').addEventListener('click', () => this.clearCart());
        document.getElementById('btn-purchase').addEventListener('click', () => this.purchase());

        document.getElementById('rotate-left').addEventListener('click', () => this.sendNUI('rotateHorse', { direction: 'left' }));
        document.getElementById('rotate-right').addEventListener('click', () => this.sendNUI('rotateHorse', { direction: 'right' }));

        document.getElementById('customize-rotate-left').addEventListener('click', () => this.sendNUI('rotateHorse', { direction: 'left' }));
        document.getElementById('customize-rotate-right').addEventListener('click', () => this.sendNUI('rotateHorse', { direction: 'right' }));

        this.setupCustomizationEvents();

        document.getElementById('confirm-close').addEventListener('click', () => this.closeConfirm());
        document.getElementById('confirm-cancel').addEventListener('click', () => this.closeConfirm());
        document.getElementById('confirm-yes').addEventListener('click', () => {
            if (this.confirmCallback) this.confirmCallback();
            this.closeConfirm();
        });

        document.getElementById('input-close').addEventListener('click', () => this.closeInput());
        document.getElementById('input-cancel').addEventListener('click', () => this.closeInput());
        document.getElementById('input-submit').addEventListener('click', () => this.submitInput());

        const backdrop = document.querySelector('.modal-backdrop');
        if (backdrop) {
            backdrop.addEventListener('click', () => {
                this.closeConfirm();
                this.closeInput();
                this.closeModal();
            });
        }

        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                if (!document.getElementById('confirm-modal').classList.contains('hidden')) {
                    this.closeConfirm();
                } else if (!document.getElementById('input-modal').classList.contains('hidden')) {
                    this.closeInput();
                } else if (this.isOpen) {
                    this.close();
                }
            }
        });
    },

    setupNUICallbacks() {
        window.addEventListener('message', (event) => {
            const data = event.data;
            if (!data || !data.action) return;

            switch (data.action) {
                case 'openStableMenu':
                    this.openStableMenu(data.stableId, data.money);
                    break;
                case 'openHorseList':
                    this.openHorseList(data.horses);
                    break;
                case 'openSellHorse':
                    this.openSellHorse(data.horses);
                    break;
                case 'openMoveSelect':
                    this.openMoveSelect(data.horses);
                    break;
                case 'openMoveDestinations':
                    this.openMoveDestinations(data.horseId, data.destinations);
                    break;
                case 'openShop':
                    this.openShop(data.items, data.money);
                    break;
                case 'openBuyTarget':
                    this.openBuyTarget(data);
                    break;
                case 'openBuyHorse':
                    this.openBuyHorse(data.horses, data.money, data.stableId);
                    break;
                case 'openHorseOptions':
                    this.openHorseOptions(data.horse);
                    break;
                case 'openBreedMareSelect':
                    this.openBreedMareSelect(data.horses);
                    break;
                case 'openBreedStallionSelect':
                    this.openBreedStallionSelect(data.horses, data.mareId);
                    break;
                case 'openCustomization':
                    this.openCustomization(data);
                    break;
                case 'showNotification':
                    this.showNotification(data.type, data.title, data.message);
                    break;
                case 'showSuccess':
                    this.showSuccess(data.message, true);
                    break;
                case 'updateMoney':
                    this.updateMoney(data.cash, data.gold);
                    break;
                case 'updatePrice':
                    document.getElementById('customize-price').textContent = '$' + (data.price || 0).toFixed(2);
                    break;
                case 'wh-open':
                    if (typeof WildHorseUI !== 'undefined') WildHorseUI.open(data.title);
                    break;
                case 'wh-close':
                    if (typeof WildHorseUI !== 'undefined') WildHorseUI.hide();
                    break;
                case 'wh-progressStart':
                    if (typeof WildHorseUI !== 'undefined') WildHorseUI.startProgress(data.duration);
                    break;
                case 'wh-progressStop':
                    if (typeof WildHorseUI !== 'undefined') WildHorseUI.stopProgress();
                    break;
                case 'close':
                    this.hide();
                    break;
                case 'setLocale':
                    Locale = data.locale || {};
                    applyStaticLocale();
                    break;
            }
        });
    },

    sendNUI(endpoint, data) {
        return fetch(`https://rsg-horses/${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data || {})
        }).catch(() => {});
    },

    openStableMenu(stableId, money) {
        this.currentStableId = stableId;
        this.isOpen = true;
        this.playerMoney = { cash: money?.cash || 0, gold: money?.gold || 0 };
        this.screenHistory = [];

        document.getElementById('shop-name').textContent = t('nui_shop_title', 'HORSE STABLE');
        document.getElementById('shop-subtitle').textContent = t('nui_shop_subtitle', 'Stable Services & Supplies');
        this.updateMoneyDisplay();
        this.setBreadcrumb([t('nui_breadcrumb_stable_menu', 'Stable Menu')]);

        const grid = document.getElementById('menu-grid');
        grid.innerHTML = '';

        const isValentine = this.currentStableId === 'valentine';
        const menuOptions = [
            { id: 'view', icon: 'icons/horse_health.png', label: t('nui_menu_view_label', 'View Horses'), desc: t('nui_menu_view_desc', 'View your horses and stats') },
            { id: 'sell', icon: 'icons/dollar.png', label: t('nui_menu_sell_label', 'Sell Horse'), desc: t('nui_menu_sell_desc', 'Sell a horse from your stable') },
            { id: 'move', icon: 'icons/transferStable.png', label: t('nui_menu_move_label', 'Move Horse'), desc: t('nui_menu_move_desc', 'Relocate horse to another stable') },
            { id: 'trade', icon: 'icons/mp_roles_trader.png', label: t('nui_menu_trade_label', 'Trade Horse'), desc: t('nui_menu_trade_desc', 'Trade with a nearby player') },
            { id: 'breed', icon: 'icons/toast_horse_bond.png', label: t('nui_menu_breed_label', 'Breed Horse'), desc: t('nui_menu_breed_desc', 'Breed two horses to get a foal') },
            { id: 'shop', icon: 'icons/horseshoes.png', label: t('nui_menu_shop_label', 'Horse Shop'), desc: t('nui_menu_shop_desc', 'Buy horse equipment and snacks') },
            { id: 'store', icon: 'icons/generic_horse_mod.png', label: t('nui_menu_store_label', 'Store Horse'), desc: t('nui_menu_store_desc', 'Put away your current horse') },
        ];
        if (isValentine) {
            menuOptions.push({ id: 'buy', icon: 'icons/animal_horse.png', label: t('nui_menu_buy_label', 'Buy Horse'), desc: t('nui_menu_buy_desc', 'Purchase a new horse') });
            menuOptions.push({ id: 'customize', icon: 'icons/horse_outfits.png', label: t('nui_menu_customize_label', 'Customize'), desc: t('nui_menu_customize_desc', 'Customize horse appearance') });
        }

        menuOptions.forEach(opt => {
            const card = document.createElement('div');
            card.className = 'item-card';
            card.innerHTML = `
                <div class="item-icon"><img src="${opt.icon}" alt=""></div>
                <div class="item-name">${opt.label}</div>
                <div class="item-subtitle">${opt.desc}</div>
            `;
            card.addEventListener('click', () => {
                this.sendNUI('stableAction', { action: opt.id, stableId: this.currentStableId });
            });
            grid.appendChild(card);
        });

        this.showScreen('main');
        document.getElementById('shop-container').classList.remove('hidden');
        const vig = document.getElementById('vignette');
        if (vig) vig.style.display = 'block';
    },

    openHorseList(horses) {
        this.pushHistory(this.currentScreen, [t('nui_breadcrumb_stable_menu', 'Stable Menu')], t('nui_footer_click_option', 'Click an option to proceed'));
        this.setBreadcrumb([t('nui_breadcrumb_stable_menu', 'Stable Menu'), t('nui_breadcrumb_view_horses', 'View Horses')]);
        document.getElementById('footer-text').textContent = t('nui_footer_click_horse_options', 'Click a horse to see options');

        const grid = document.getElementById('horse-grid');
        const noItems = document.getElementById('no-horses');
        grid.innerHTML = '';

        if (!horses || horses.length === 0) {
            grid.classList.add('hidden');
            noItems.classList.remove('hidden');
            this.showScreen('horse-list');
            return;
        }

        grid.classList.remove('hidden');
        noItems.classList.add('hidden');

        horses.forEach(horse => {
            const card = document.createElement('div');
            card.className = 'item-card';
            const isActive = horse.active === 1 || horse.active === true;
            card.innerHTML = `
                <div class="item-icon"><img src="icons/animal_horse.png" alt=""></div>
                <div class="item-name">${horse.name || t('nui_unknown', 'Unknown')}</div>
                <div class="item-subtitle">${t('nui_level_gender_format', 'Level %s | %s').replace('%s', horse.level || 1).replace('%s', horse.gender || t('nui_unknown', 'Unknown'))}</div>
                <div class="horse-stats">
                    <span class="horse-stat-badge">XP: ${horse.horsexp || 0}</span>
                    <span class="horse-stat-badge ${isActive ? 'active' : 'inactive'}">${isActive ? t('nui_active', 'Active') : t('nui_stabled', 'Stabled')}</span>
                    <span class="horse-stat-badge">${t('nui_clean_percent', 'Clean: %s%%').replace('%s', 100 - (horse.dirt || 0))}</span>
                </div>
            `;
            card.addEventListener('click', () => {
                this.sendNUI('selectHorse', { horse });
            });
            grid.appendChild(card);
        });

        this.showScreen('horse-list');
    },

    openHorseOptions(horse) {
        this.pushHistory(this.currentScreen, [t('nui_breadcrumb_stable_menu', 'Stable Menu'), t('nui_breadcrumb_view_horses', 'View Horses')], t('nui_footer_click_horse_options', 'Click a horse to see options'));
        this.setBreadcrumb([t('nui_breadcrumb_stable_menu', 'Stable Menu'), t('nui_breadcrumb_view_horses', 'View Horses'), horse.name || t('nui_options_fallback', 'Options')]);
        document.getElementById('footer-text').textContent = t('nui_footer_options_for', 'Options for %s').replace('%s', horse.name || t('nui_horse_fallback', 'horse'));

        const grid = document.getElementById('horse-grid');
        grid.innerHTML = '';

        const options = [
            { id: 'ride', icon: 'icons/menu_icon_on_horse.png', label: t('nui_option_ride_label', 'Ride Horse'), desc: t('nui_option_ride_desc', 'Set as active and call horse') },
        ];
        options.forEach(opt => {
            const card = document.createElement('div');
            card.className = 'item-card';
            card.innerHTML = `
                <div class="item-icon"><img src="${opt.icon}" alt=""></div>
                <div class="item-name">${opt.label}</div>
                <div class="item-subtitle">${opt.desc}</div>
            `;
            card.addEventListener('click', () => {
                this.sendNUI('horseOption', { option: opt.id, horse });
            });
            grid.appendChild(card);
        });

        this.showScreen('horse-list');
    },

    openSellHorse(horses) {
        this.pushHistory(this.currentScreen, [t('nui_breadcrumb_stable_menu', 'Stable Menu')], t('nui_footer_click_option', 'Click an option to proceed'));
        this.setBreadcrumb([t('nui_breadcrumb_stable_menu', 'Stable Menu'), t('nui_menu_sell_label', 'Sell Horse')]);
        document.getElementById('footer-text').textContent = t('nui_footer_click_sell', 'Click a horse to sell it');

        const grid = document.getElementById('sell-grid');
        const noItems = document.getElementById('no-sell-horses');
        grid.innerHTML = '';

        if (!horses || horses.length === 0) {
            grid.classList.add('hidden');
            noItems.classList.remove('hidden');
            this.showScreen('sell-horse');
            return;
        }

        grid.classList.remove('hidden');
        noItems.classList.add('hidden');

        horses.forEach(horse => {
            const card = document.createElement('div');
            card.className = 'item-card';
            card.innerHTML = `
                <div class="item-icon"><img src="icons/animal_horse.png" alt=""></div>
                <div class="item-name">${horse.name || t('nui_unknown', 'Unknown')}</div>
                <div class="item-subtitle">${t('nui_level_gender_format', 'Level %s | %s').replace('%s', horse.level || 1).replace('%s', horse.gender || t('nui_unknown', 'Unknown'))}</div>
                <div class="item-price">$${(horse.sellPrice || 0).toFixed(2)}</div>
                <div class="item-stat">XP: ${horse.horsexp || 0}</div>
            `;
            card.addEventListener('click', () => {
                this.showConfirm(
                    t('nui_menu_sell_label', 'Sell Horse'),
                    t('nui_confirm_sell_message', 'Are you sure you want to sell %s for $%s? This cannot be undone.').replace('%s', horse.name).replace('%s', (horse.sellPrice || 0).toFixed(2)),
                    () => {
                        this.sendNUI('confirmSell', { horseId: horse.id });
                        this.showSuccess(t('nui_sold_success', '%s has been sold!').replace('%s', horse.name), true);
                    }
                );
            });
            grid.appendChild(card);
        });

        this.showScreen('sell-horse');
    },

    openMoveSelect(horses) {
        this.pushHistory(this.currentScreen, [t('nui_breadcrumb_stable_menu', 'Stable Menu')], t('nui_footer_click_option', 'Click an option to proceed'));
        this.setBreadcrumb([t('nui_breadcrumb_stable_menu', 'Stable Menu'), t('nui_menu_move_label', 'Move Horse')]);
        document.getElementById('footer-text').textContent = t('nui_footer_select_move', 'Select a horse to move');

        const grid = document.getElementById('move-select-grid');
        const noItems = document.getElementById('no-move-horses');
        grid.innerHTML = '';

        if (!horses || horses.length === 0) {
            grid.classList.add('hidden');
            noItems.classList.remove('hidden');
            this.showScreen('move-select');
            return;
        }

        grid.classList.remove('hidden');
        noItems.classList.add('hidden');

        horses.forEach(horse => {
            const card = document.createElement('div');
            card.className = 'item-card';
            const isActive = horse.active === 1 || horse.active === true;
            card.innerHTML = `
                <div class="item-icon"><img src="icons/animal_horse.png" alt=""></div>
                <div class="item-name">${horse.name || t('nui_unknown', 'Unknown')}</div>
                <div class="item-subtitle">${t('nui_level_format', 'Level %s').replace('%s', horse.level || 1)}</div>
                <div class="horse-stats">
                    <span class="horse-stat-badge ${isActive ? 'active' : 'inactive'}">${isActive ? t('nui_active', 'Active') : t('nui_stabled', 'Stabled')}</span>
                </div>
            `;
            card.addEventListener('click', () => {
                this.sendNUI('selectMoveHorse', { horseId: horse.id, currentStableId: horse.stable });
            });
            grid.appendChild(card);
        });

        this.showScreen('move-select');
    },

    openMoveDestinations(horseId, destinations) {
        this.moveHorseId = horseId;
        this.pushHistory(this.currentScreen, [t('nui_breadcrumb_stable_menu', 'Stable Menu'), t('nui_menu_move_label', 'Move Horse')], t('nui_footer_select_move', 'Select a horse to move'));
        this.setBreadcrumb([t('nui_breadcrumb_stable_menu', 'Stable Menu'), t('nui_menu_move_label', 'Move Horse'), t('nui_breadcrumb_destination', 'Destination')]);
        document.getElementById('footer-text').textContent = t('nui_footer_select_dest', 'Select destination stable');

        const grid = document.getElementById('move-dest-grid');
        const noItems = document.getElementById('no-move-dests');
        grid.innerHTML = '';

        if (!destinations || destinations.length === 0) {
            grid.classList.add('hidden');
            noItems.classList.remove('hidden');
            this.showScreen('move-destination');
            return;
        }

        grid.classList.remove('hidden');
        noItems.classList.add('hidden');

        destinations.forEach(dest => {
            const card = document.createElement('div');
            card.className = 'item-card';
            card.innerHTML = `
                <div class="item-icon"><img src="icons/transferStable.png" alt=""></div>
                <div class="item-name">${dest.label}</div>
                <div class="item-price">$${(dest.cost || 0).toFixed(2)}</div>
                <div class="item-stat">${t('nui_fee_to_move', 'Fee to move')}</div>
            `;
            card.addEventListener('click', () => {
                this.sendNUI('confirmMove', { horseId: this.moveHorseId, destStable: dest.stableId });
                this.showSuccess(t('nui_move_success', 'Horse moved successfully!'), true);
            });
            grid.appendChild(card);
        });

        this.showScreen('move-destination');
    },

    openBreedMareSelect(horses) {
        this.pushHistory(this.currentScreen, [t('nui_breadcrumb_stable_menu', 'Stable Menu')], t('nui_footer_click_option', 'Click an option to proceed'));
        this.setBreadcrumb([t('nui_breadcrumb_stable_menu', 'Stable Menu'), t('nui_menu_breed_label', 'Breed Horse'), t('nui_select_mare', 'Select Mare')]);
        document.getElementById('footer-text').textContent = t('nui_footer_select_mare', 'Select a female horse (mare) to breed');

        const grid = document.getElementById('breed-mare-grid');
        const noItems = document.getElementById('no-breed-mares');
        grid.innerHTML = '';

        if (!horses || horses.length === 0) {
            grid.classList.add('hidden');
            noItems.classList.remove('hidden');
            this.showScreen('breed-mare');
            return;
        }

        grid.classList.remove('hidden');
        noItems.classList.add('hidden');

        horses.forEach(horse => {
            const card = document.createElement('div');
            card.className = 'item-card';
            const isPregnant = horse.pregnant_until && horse.pregnant_until > Math.floor(Date.now() / 1000);
            const ageLabel = horse.age_seconds ? this.getHorseAgeLabel(horse.age_seconds) : t('nui_unknown', 'Unknown');
            card.innerHTML = `
                <div class="item-icon"><img src="icons/female.png" alt=""></div>
                <div class="item-name">${horse.name || t('nui_unknown', 'Unknown')}</div>
                <div class="item-subtitle">${horse.horse || t('nui_unknown_breed', 'Unknown breed')}</div>
                <div class="horse-stats">
                    <span class="horse-stat-badge">${t('nui_age_format', 'Age: %s').replace('%s', ageLabel)}</span>
                    <span class="horse-stat-badge ${isPregnant ? 'active' : ''}">${isPregnant ? t('nui_pregnant', 'Pregnant') : t('nui_ready', 'Ready')}</span>
                </div>
            `;
            if (!isPregnant) {
                card.addEventListener('click', () => {
                    this.sendNUI('selectBreedingMare', { mareId: horse.id });
                });
            } else {
                card.classList.add('disabled');
            }
            grid.appendChild(card);
        });

        this.showScreen('breed-mare');
    },

    openBreedStallionSelect(horses, mareId) {
        this.selectedMareId = mareId;
        this.pushHistory(this.currentScreen, [t('nui_breadcrumb_stable_menu', 'Stable Menu'), t('nui_menu_breed_label', 'Breed Horse')], t('nui_footer_select_mare', 'Select a female horse (mare) to breed'));
        this.setBreadcrumb([t('nui_breadcrumb_stable_menu', 'Stable Menu'), t('nui_menu_breed_label', 'Breed Horse'), t('nui_select_stallion', 'Select Stallion')]);
        document.getElementById('footer-text').textContent = t('nui_footer_select_stallion', 'Select a male horse (stallion) to breed');

        const grid = document.getElementById('breed-stallion-grid');
        const noItems = document.getElementById('no-breed-stallions');
        grid.innerHTML = '';

        if (!horses || horses.length === 0) {
            grid.classList.add('hidden');
            noItems.classList.remove('hidden');
            this.showScreen('breed-stallion');
            return;
        }

        grid.classList.remove('hidden');
        noItems.classList.add('hidden');

        horses.forEach(horse => {
            const card = document.createElement('div');
            card.className = 'item-card';
            const ageLabel = horse.age_seconds ? this.getHorseAgeLabel(horse.age_seconds) : t('nui_unknown', 'Unknown');
            card.innerHTML = `
                <div class="item-icon"><img src="icons/male.png" alt=""></div>
                <div class="item-name">${horse.name || t('nui_unknown', 'Unknown')}</div>
                <div class="item-subtitle">${horse.horse || t('nui_unknown_breed', 'Unknown breed')}</div>
                <div class="horse-stats">
                    <span class="horse-stat-badge">${t('nui_age_format', 'Age: %s').replace('%s', ageLabel)}</span>
                </div>
            `;
            card.addEventListener('click', () => {
                this.showConfirm(
                    t('nui_confirm_breeding_title', 'Confirm Breeding'),
                    t('nui_confirm_breeding_message', 'Breed %s (stallion) with your mare? This will cost hay and start gestation.').replace('%s', horse.name),
                    () => {
                        this.sendNUI('confirmBreed', { mareId: this.selectedMareId, stallionId: horse.id });
                        this.showSuccess(t('nui_breeding_started', 'Breeding started! Check back later for your foal.'), true);
                    }
                );
            });
            grid.appendChild(card);
        });

        this.showScreen('breed-stallion');
    },

    getHorseAgeLabel(ageSeconds) {
        if (!ageSeconds || ageSeconds <= 0) return t('nui_newborn', 'Newborn');
        const mins = ageSeconds / 60;
        const hours = mins / 60;
        if (hours >= 1) return hours.toFixed(1) + 'h';
        return Math.floor(mins) + 'm';
    },

    openShop(items, money) {
        this.playerMoney = { cash: money?.cash || 0, gold: money?.gold || 0 };
        this.cart = [];
        this.currentScreen = 'shop';
        this.pushHistory(this.currentScreen, ['Stable Menu'], 'Click an option to proceed');

        this.setBreadcrumb([t('nui_breadcrumb_stable_menu', 'Stable Menu'), t('nui_menu_shop_label', 'Horse Shop')]);
        document.getElementById('footer-text').textContent = t('nui_footer_click_items', 'Click items to add to cart');
        document.getElementById('filter-bar').style.display = '';
        document.getElementById('sort-options').style.display = '';

        this.updateMoneyDisplay();
        this.renderShopItems(items || []);
        this.updateCartDisplay();

        this.showScreen('shop');
    },

    renderShopItems(items) {
        const grid = document.getElementById('shop-grid');
        const noItems = document.getElementById('no-shop-items');
        grid.innerHTML = '';

        let filtered = (items || []).filter(item => {
            if (!item) return false;
            const q = this.searchQuery || '';
            if (!q) return true;
            return (item.label || item.name || '').toLowerCase().includes(q);
        });

        filtered.sort((a, b) => {
            switch (this.sortBy) {
                case 'price-low': return (a.price || 0) - (b.price || 0);
                case 'price-high': return (b.price || 0) - (a.price || 0);
                default: return (a.label || a.name || '').localeCompare(b.label || b.name || '');
            }
        });

        if (filtered.length === 0) {
            grid.classList.add('hidden');
            noItems.classList.remove('hidden');
            return;
        }

        grid.classList.remove('hidden');
        noItems.classList.add('hidden');

        filtered.forEach(item => {
            const card = document.createElement('div');
            card.className = `item-card ${(item.amount || 0) <= 0 ? 'disabled' : ''}`;
            const icon = this.getItemIcon(item);
            const label = item.label || item.name || t('nui_item_fallback', 'Item');

            card.innerHTML = `
                <div class="item-icon"><img src="${icon}" alt=""></div>
                <div class="item-name">${label}</div>
                <div class="item-price">$${(item.price || 0).toFixed(2)}</div>
                <div class="item-stat">${t('nui_stock_format', 'Stock: %s').replace('%s', item.amount || 0)}</div>
            `;

            if ((item.amount || 0) > 0) {
                card.addEventListener('click', () => {
                    this.selectedItem = item;
                    this.showItemModal(item);
                });
            }

            grid.appendChild(card);
        });
    },

    getItemIcon(item) {
        if (!item || !item.name) return 'icons/propsets.png';
        const n = item.name.toLowerCase();
        if (n.includes('brush')) return 'icons/horseBrush.png';
        if (n.includes('lantern') || n.includes('lamp')) return 'icons/saddle_lanterns.png';
        if (n.includes('carrot') || n.includes('apple') || n.includes('feed')) return 'icons/toast_horse_bond.png';
        if (n.includes('stimulant') || n.includes('reviver') || n.includes('medic')) return 'icons/horse_health.png';
        if (n.includes('holster')) return 'icons/holsters_left.png';
        return 'icons/propsets.png';
    },

    showItemModal(item) {
        this.selectedItem = item;
        const modal = document.getElementById('item-modal');
        if (!modal) return;

        const label = item.label || item.name || t('nui_item_fallback', 'Item');
        const icon = this.getItemIcon(item);

        document.getElementById('modal-item-name').textContent = label;
        document.getElementById('modal-item-type').textContent = item.type || t('nui_horse_item_fallback', 'Horse Item');
        document.getElementById('modal-price').textContent = '$' + (item.price || 0).toFixed(2);
        document.getElementById('modal-stock').textContent = item.amount || 0;
        document.getElementById('modal-icon').innerHTML = `<img src="${icon}" alt="">`;

        const qtyInput = document.getElementById('qty-input');
        if (qtyInput) {
            qtyInput.value = 1;
            qtyInput.max = item.amount || 1;
        }

        this.updateModalTotal();
        modal.classList.remove('hidden');

        document.getElementById('qty-minus').onclick = () => this.adjustQuantity(-1);
        document.getElementById('qty-plus').onclick = () => this.adjustQuantity(1);
        document.getElementById('qty-input').onchange = () => this.updateModalTotal();
        document.querySelectorAll('.quick-btn').forEach(btn => {
            btn.onclick = () => {
                if (!this.selectedItem) return;
                const qty = btn.dataset.qty;
                const input = document.getElementById('qty-input');
                if (qty === 'max') {
                    input.value = this.selectedItem.amount || 1;
                } else {
                    input.value = Math.min(parseInt(qty), this.selectedItem.amount || 1);
                }
                this.updateModalTotal();
            };
        });
        document.getElementById('modal-close').onclick = () => this.closeModal();
        document.getElementById('modal-cancel').onclick = () => this.closeModal();
        document.getElementById('modal-add').onclick = () => this.addToCart();
    },

    adjustQuantity(delta) {
        if (!this.selectedItem) return;
        const input = document.getElementById('qty-input');
        if (!input) return;
        let value = parseInt(input.value) + delta;
        value = Math.max(1, Math.min(value, this.selectedItem.amount || 1));
        input.value = value;
        this.updateModalTotal();
    },

    updateModalTotal() {
        if (!this.selectedItem) return;
        const input = document.getElementById('qty-input');
        const totalEl = document.getElementById('modal-total');
        if (!input || !totalEl) return;
        const qty = parseInt(input.value) || 1;
        totalEl.textContent = '$' + (qty * (this.selectedItem.price || 0)).toFixed(2);
    },

    closeModal() {
        const modal = document.getElementById('item-modal');
        if (modal) modal.classList.add('hidden');
        this.selectedItem = null;
    },

    addToCart() {
        if (!this.selectedItem) return;
        const input = document.getElementById('qty-input');
        const qty = input ? (parseInt(input.value) || 1) : 1;

        const existing = this.cart.find(c => c.name === this.selectedItem.name);
        if (existing) {
            const newQty = existing.quantity + qty;
            if (newQty > (this.selectedItem.amount || 0)) {
                this.showNotification('error', t('nui_stock_limit_title', 'Stock Limit'), t('nui_stock_limit_message', 'Cannot add more than available stock'));
                return;
            }
            existing.quantity = newQty;
        } else {
            this.cart.push({
                name: this.selectedItem.name,
                label: this.selectedItem.label || this.selectedItem.name,
                price: this.selectedItem.price || 0,
                quantity: qty,
                icon: this.getItemIcon(this.selectedItem)
            });
        }

        this.updateCartDisplay();
        this.closeModal();
        this.showNotification('success', t('nui_added_to_cart_title', 'Added to Cart'), `${qty}x ${this.selectedItem.label || this.selectedItem.name}`);
    },

    updateCartDisplay() {
        const cartItems = document.getElementById('cart-items');
        const cartEmpty = document.getElementById('cart-empty');
        const cartCount = document.getElementById('cart-count');
        const purchaseBtn = document.getElementById('btn-purchase');

        const totalItems = this.cart.reduce((sum, item) => sum + (item.quantity || 0), 0);
        if (cartCount) cartCount.textContent = totalItems;

        if (this.cart.length === 0) {
            if (cartItems) cartItems.classList.add('hidden');
            if (cartEmpty) cartEmpty.classList.remove('hidden');
            document.getElementById('cart-subtotal').textContent = '$0.00';
            document.getElementById('cart-total').textContent = '$0.00';
            if (purchaseBtn) purchaseBtn.disabled = true;
            return;
        }

        if (cartItems) cartItems.classList.remove('hidden');
        if (cartEmpty) cartEmpty.classList.add('hidden');
        if (purchaseBtn) purchaseBtn.disabled = false;

        if (!cartItems) return;
        cartItems.innerHTML = '';
        let subtotal = 0;

        this.cart.forEach((item, index) => {
            const itemTotal = (item.price || 0) * (item.quantity || 0);
            subtotal += itemTotal;

            const el = document.createElement('div');
            el.className = 'cart-item';
            el.innerHTML = `
                <div class="cart-item-image"><img src="${item.icon || 'icons/propsets.png'}" alt=""></div>
                <div class="cart-item-info">
                    <div class="cart-item-name">${item.label || 'Item'}</div>
                    <div class="cart-item-qty">x${item.quantity || 0}</div>
                </div>
                <div class="cart-item-price">$${itemTotal.toFixed(2)}</div>
                <button class="cart-item-remove" data-index="${index}"><img src="icons/cross.png" alt=""></button>
            `;
            el.querySelector('.cart-item-remove').addEventListener('click', () => {
                this.cart.splice(index, 1);
                this.updateCartDisplay();
            });
            cartItems.appendChild(el);
        });

        document.getElementById('cart-subtotal').textContent = '$' + subtotal.toFixed(2);
        const cartTotalEl = document.getElementById('cart-total');
        cartTotalEl.textContent = '$' + subtotal.toFixed(2);
        const canAffordCart = subtotal <= (this.playerMoney.cash || 0);
        cartTotalEl.classList.toggle('over', !canAffordCart);
        if (purchaseBtn) purchaseBtn.disabled = !canAffordCart;
    },

    clearCart() {
        this.cart = [];
        this.updateCartDisplay();
    },

    purchase() {
        if (this.cart.length === 0) return;
        const total = this.cart.reduce((sum, item) => sum + ((item.price || 0) * (item.quantity || 0)), 0);

        if (total > (this.playerMoney.cash || 0)) {
            this.showNotification('error', t('nui_insufficient_funds_title', 'Insufficient Funds'), t('nui_insufficient_funds_message', "You don't have enough cash"));
            return;
        }

        const purchaseBtn = document.getElementById('btn-purchase');
        if (purchaseBtn) {
            purchaseBtn.classList.add('purchasing');
            purchaseBtn.disabled = true;
        }

        this.sendNUI('purchaseItems', {
            items: this.cart,
            total: total
        });
    },

    openBuyHorse(horses, money, stableId) {
        this.playerMoney = { cash: money?.cash || 0, gold: money?.gold || 0 };
        if (stableId) this.currentStableId = stableId;
        this.currentScreen = 'buy-horse';
        this.selectedHorse = null;
        this.buyHorses = horses || [];
        this.pushHistory(this.currentScreen, ['Stable Menu'], 'Click an option to proceed');

        this.setBreadcrumb([t('nui_breadcrumb_stable_menu', 'Stable Menu'), t('nui_menu_buy_label', 'Buy Horse')]);
        document.getElementById('footer-text').textContent = t('nui_footer_click_preview', 'Click a horse to preview');
        document.getElementById('filter-bar').style.display = '';
        document.getElementById('sort-options').style.display = '';

        this.updateMoneyDisplay();

        const grid = document.getElementById('buy-grid');
        const noItems = document.getElementById('no-buy-horses');
        grid.innerHTML = '';

        if (!horses || horses.length === 0) {
            grid.classList.add('hidden');
            noItems.classList.remove('hidden');
            this.showScreen('buy-horse');
            return;
        }

        grid.classList.remove('hidden');
        noItems.classList.add('hidden');

        horses.forEach((horse, index) => {
            const price = horse.horseprice || horse.price || 0;
            const canAfford = price <= (this.playerMoney.cash || 0);

            const card = document.createElement('div');
            card.className = `item-card ${horse.disabled ? 'disabled' : ''} ${!horse.disabled && !canAfford ? 'unaffordable' : ''}`;
            card.dataset.model = horse.horsemodel || horse.model || '';
            const shortfallHtml = (!horse.disabled && !canAfford)
                ? `<div class="item-shortfall">${t('nui_short_by', 'Short by $%s').replace('%s', Math.max(0, price - (this.playerMoney.cash || 0)).toFixed(2))}</div>`
                : '';
            card.innerHTML = `
                <div class="item-icon"><img src="icons/animal_horse.png" alt=""></div>
                <div class="item-name">${horse.horsename || horse.name || t('nui_horse_name_fallback', 'Horse')}</div>
                <div class="item-subtitle">${horse.horsemodel || horse.model || ''}</div>
                <div class="item-price ${canAfford ? '' : 'over'}">$${price.toFixed(2)}</div>
                ${shortfallHtml}
                <button class="buy-btn" data-model="${horse.horsemodel || horse.model || ''}" ${canAfford ? '' : 'disabled'}><img src="icons/dollar.png" alt=""> ${t('nui_buy', 'BUY')}</button>
            `;
            if (!horse.disabled) {
                const buyBtn = card.querySelector('.buy-btn');
                buyBtn.addEventListener('click', (e) => {
                    e.stopPropagation();
                    if (buyBtn.disabled) return;
                    const currentPrice = horse.horseprice || horse.price || 0;
                    if (currentPrice > (this.playerMoney.cash || 0)) {
                        this.showNotification('error', t('nui_insufficient_funds_title', 'Insufficient Funds'), t('nui_insufficient_funds_message', "You don't have enough cash"));
                        return;
                    }
                    this.showBuyHorseDialog(horse);
                });
                card.addEventListener('click', () => {
                    grid.querySelectorAll('.item-card').forEach(c => c.classList.remove('selected'));
                    card.classList.add('selected');
                    this.selectedHorse = horse;
                    this.sendNUI('previewHorse', { model: horse.horsemodel || horse.model });
                });
            }
            grid.appendChild(card);
        });

        if (horses[0] && !horses[0].disabled) {
            const firstCard = grid.querySelector('.item-card:not(.disabled)');
            if (firstCard) {
                firstCard.classList.add('selected');
                this.selectedHorse = horses[0];
                this.sendNUI('previewHorse', { model: horses[0].horsemodel || horses[0].model });
            }
        }

        this.showScreen('buy-horse');
    },

    openBuyTarget(data) {
        document.getElementById('input-title').textContent = t('nui_menu_buy_label', 'Buy Horse');
        document.getElementById('input-label').textContent = t('nui_enter_horse_name', 'Enter a name for your new horse:');
        document.getElementById('input-field').value = '';
        document.getElementById('input-field').placeholder = t('nui_horse_name_placeholder', 'Horse name...');
        document.getElementById('input-select-group').style.display = 'block';
        document.getElementById('input-select-label').textContent = t('nui_select_gender', 'Select Gender:');

        const select = document.getElementById('input-select');
        select.innerHTML = `
            <option value="male">${t('nui_gelding', 'Gelding')}</option>
            <option value="female">${t('nui_mare', 'Mare')}</option>
        `;

        this.inputCallback = () => {
            const name = document.getElementById('input-field').value.trim();
            const gender = document.getElementById('input-select').value;
            if (!name) {
                this.showNotification('error', t('nui_invalid_name_title', 'Invalid Name'), t('nui_invalid_name_message', 'Please enter a horse name'));
                return;
            }
            this.sendNUI('buyTarget', {
                model: data.horsemodel,
                stableId: this.currentStableId,
                name: name,
                gender: gender
            });
            this.closeInput();
            this.showSuccess(t('nui_horse_is_yours', '%s the %s is yours!').replace('%s', name).replace('%s', gender === 'male' ? t('nui_gelding', 'Gelding') : t('nui_mare', 'Mare')), true);
        };

        document.getElementById('input-modal').classList.remove('hidden');
        setTimeout(() => document.getElementById('input-field').focus(), 100);
    },

    showBuyHorseDialog(horse) {
        const price = horse.horseprice || horse.price || 0;
        if (price > (this.playerMoney.cash || 0)) {
            this.showNotification('error', t('nui_insufficient_funds_title', 'Insufficient Funds'), t('nui_insufficient_funds_message', "You don't have enough cash"));
            return;
        }
        document.getElementById('input-title').textContent = t('nui_menu_buy_label', 'Buy Horse');
        document.getElementById('input-label').textContent = t('nui_enter_horse_name', 'Enter a name for your new horse:');
        document.getElementById('input-field').value = '';
        document.getElementById('input-field').placeholder = t('nui_horse_name_placeholder', 'Horse name...');
        document.getElementById('input-select-group').style.display = 'block';
        document.getElementById('input-select-label').textContent = t('nui_select_gender', 'Select Gender:');

        const select = document.getElementById('input-select');
        select.innerHTML = `
            <option value="male">${t('nui_gelding', 'Gelding')}</option>
            <option value="female">${t('nui_mare', 'Mare')}</option>
        `;

        this.inputCallback = () => {
            const name = document.getElementById('input-field').value.trim();
            const gender = document.getElementById('input-select').value;
            if (!name) {
                this.showNotification('error', t('nui_invalid_name_title', 'Invalid Name'), t('nui_invalid_name_message', 'Please enter a horse name'));
                return;
            }
            this.sendNUI('buyHorse', {
                model: horse.horsemodel || horse.model,
                stableId: this.currentStableId,
                name: name,
                gender: gender
            });
            this.closeInput();
            this.showSuccess(t('nui_horse_is_yours', '%s the %s is yours!').replace('%s', name).replace('%s', gender === 'male' ? t('nui_gelding', 'Gelding') : t('nui_mare', 'Mare')), true);
        };

        document.getElementById('input-modal').classList.remove('hidden');
        setTimeout(() => document.getElementById('input-field').focus(), 100);
    },

    showConfirm(title, message, callback) {
        document.getElementById('confirm-title').textContent = title;
        document.getElementById('confirm-message').textContent = message;
        this.confirmCallback = callback;
        document.getElementById('confirm-modal').classList.remove('hidden');
    },

    closeConfirm() {
        document.getElementById('confirm-modal').classList.add('hidden');
        this.confirmCallback = null;
    },

    closeInput() {
        document.getElementById('input-modal').classList.add('hidden');
        this.inputCallback = null;
    },

    submitInput() {
        if (this.inputCallback) this.inputCallback();
    },

    showSuccess(message, autoClose) {
        document.getElementById('success-message').textContent = message || t('nui_action_completed', 'Action completed');
        const overlay = document.getElementById('success-overlay');
        overlay.classList.remove('hidden');
        setTimeout(() => {
            overlay.classList.add('hidden');
            if (autoClose) this.close();
        }, 2500);
    },

    showNotification(type, title, message) {
        const container = document.getElementById('notification-container');
        if (!container) return;

        const icons = {
            success: 'icons/tick.png',
            error: 'icons/cross.png',
            info: 'icons/information.png'
        };

        const notif = document.createElement('div');
        notif.className = `notification ${type}`;
        notif.innerHTML = `
            <img src="${icons[type] || icons.info}" alt="">
            <div>
                <strong>${title || t('nui_notice_default', 'Notice')}</strong>
                ${message ? `<span class="notif-sub">${message}</span>` : ''}
            </div>
        `;

        container.appendChild(notif);
        setTimeout(() => {
            notif.style.animation = 'notifyOut 0.25s ease-in forwards';
            setTimeout(() => notif.remove(), 250);
        }, 4000);
    },

    close() {
        this.sendNUI('closeUI');
        this.hide();
    },

    hide() {
        this.isOpen = false;
        this.cart = [];
        this.selectedHorse = null;
        this.moveHorseId = null;
        this.selectedMareId = null;
        this.screenHistory = [];
        this.confirmCallback = null;
        this.inputCallback = null;

        // If on customize screen, notify Lua to clean up camera
        if (this.currentScreen === 'customize') {
            this.sendNUI('closeCustomization', {});
        }

        document.getElementById('shop-container').classList.add('hidden');
        const vig = document.getElementById('vignette');
        if (vig) vig.style.display = 'none';
        document.getElementById('confirm-modal').classList.add('hidden');
        document.getElementById('input-modal').classList.add('hidden');
        document.getElementById('item-modal')?.classList.add('hidden');
        const backBtn = document.getElementById('back-btn');
        if (backBtn) backBtn.style.display = 'none';
        this.closeModal();

        const purchaseBtn = document.getElementById('btn-purchase');
        if (purchaseBtn) {
            purchaseBtn.classList.remove('purchasing');
            purchaseBtn.disabled = false;
        }
    },

    updateMoneyDisplay() {
        const cashEl = document.getElementById('player-cash');
        if (cashEl) cashEl.textContent = '$' + (this.playerMoney.cash || 0).toFixed(2);
        const goldEl = document.getElementById('player-gold');
        if (goldEl) goldEl.textContent = this.playerMoney.gold || 0;
    },

    updateMoney(cash, gold) {
        this.playerMoney = { cash: cash || 0, gold: gold || 0 };
        this.updateMoneyDisplay();
        if (this.currentScreen === 'buy-horse') this.updateBuyGridAffordability();
        if (this.currentScreen === 'shop') this.updateCartDisplay();
    },

    updateBuyGridAffordability() {
        const grid = document.getElementById('buy-grid');
        if (!grid || !this.buyHorses) return;
        grid.querySelectorAll('.item-card').forEach(card => {
            const model = card.dataset.model;
            const horse = this.buyHorses.find(h => (h.horsemodel || h.model || '') === model);
            if (!horse || horse.disabled) return;

            const price = horse.horseprice || horse.price || 0;
            const canAfford = price <= (this.playerMoney.cash || 0);

            const priceEl = card.querySelector('.item-price');
            if (priceEl) priceEl.classList.toggle('over', !canAfford);

            let shortfallEl = card.querySelector('.item-shortfall');
            if (!canAfford) {
                const shortfall = Math.max(0, price - (this.playerMoney.cash || 0));
                const text = t('nui_short_by', 'Short by $%s').replace('%s', shortfall.toFixed(2));
                if (!shortfallEl) {
                    shortfallEl = document.createElement('div');
                    shortfallEl.className = 'item-shortfall';
                    if (priceEl) priceEl.insertAdjacentElement('afterend', shortfallEl);
                }
                shortfallEl.textContent = text;
            } else if (shortfallEl) {
                shortfallEl.remove();
            }

            card.classList.toggle('unaffordable', !canAfford);
            const btn = card.querySelector('.buy-btn');
            if (btn) btn.disabled = !canAfford;
        });
    },

    setBreadcrumb(items) {
        const bc = document.getElementById('breadcrumb');
        bc.innerHTML = '';
        items.forEach((item, i) => {
            const span = document.createElement('span');
            span.className = 'breadcrumb-item' + (i === items.length - 1 ? ' active' : '');
            if (i < items.length - 1) {
                span.style.cursor = 'pointer';
                const clickIndex = i;
                span.addEventListener('click', () => {
                    if (clickIndex === 0) {
                        this.showScreen('main');
                    } else {
                        while (this.screenHistory.length > clickIndex) {
                            this.screenHistory.pop();
                        }
                        this.goBack();
                    }
                });
            }
            span.textContent = item;
            bc.appendChild(span);
            if (i < items.length - 1) {
                const sep = document.createElement('span');
                sep.style.color = 'var(--rdr-gold-dim)';
                sep.style.margin = '0 4px';
                sep.textContent = '›';
                bc.appendChild(sep);
            }
        });
    },

    showScreen(screen) {
        this.currentScreen = screen;
        document.querySelectorAll('.screen').forEach(s => s.classList.add('hidden'));
        const el = document.getElementById('screen-' + screen);
        if (el) el.classList.remove('hidden');

        // Buy-horse catalogue gets the expanded wide panel
        this.applyWideMode(screen);

        const backBtn = document.getElementById('back-btn');
        if (screen === 'main') {
            this.screenHistory = [];
            if (backBtn) backBtn.style.display = 'none';
        } else {
            if (backBtn) backBtn.style.display = '';
        }

        if (screen === 'shop' || screen === 'buy-horse') {
            document.getElementById('filter-bar').style.display = '';
            document.getElementById('sort-options').style.display = screen === 'shop' ? '' : 'none';
        } else {
            document.getElementById('filter-bar').style.display = 'none';
            document.getElementById('sort-options').style.display = 'none';
        }
    },

    applyWideMode(screen) {
        const container = document.getElementById('shop-container');
        if (container) container.classList.toggle('wide', screen === 'buy-horse' || screen === 'customize');
    },

    goBack() {
        if (this.screenHistory.length > 0) {
            const prev = this.screenHistory.pop();
            this.currentScreen = prev.screen;
            document.querySelectorAll('.screen').forEach(s => s.classList.add('hidden'));
            const el = document.getElementById('screen-' + prev.screen);
            if (el) el.classList.remove('hidden');

            // Keep wide panel in sync when navigating back
            this.applyWideMode(prev.screen);

            if (prev.breadcrumb) this.setBreadcrumb(prev.breadcrumb);
            if (prev.footer) document.getElementById('footer-text').textContent = prev.footer;

            const backBtn = document.getElementById('back-btn');
            if (prev.screen === 'main') {
                this.screenHistory = [];
                if (backBtn) backBtn.style.display = 'none';
            } else {
                if (backBtn) backBtn.style.display = '';
            }

            if (prev.screen === 'shop' || prev.screen === 'buy-horse') {
                document.getElementById('filter-bar').style.display = '';
                document.getElementById('sort-options').style.display = prev.screen === 'shop' ? '' : 'none';
            } else {
                document.getElementById('filter-bar').style.display = 'none';
                document.getElementById('sort-options').style.display = 'none';
            }
        } else {
            this.showScreen('main');
        }
    },

    pushHistory(screen, breadcrumb, footer) {
        this.screenHistory.push({ screen, breadcrumb, footer });
    },

    openCustomization(data) {
        this.pushHistory(this.currentScreen, [t('nui_breadcrumb_stable_menu', 'Stable Menu'), t('nui_menu_customize_label', 'Customize')], t('nui_footer_click_option', 'Click an option to proceed'));
        this.setBreadcrumb([t('nui_breadcrumb_stable_menu', 'Stable Menu'), t('nui_menu_customize_label', 'Customize'), t('nui_components', 'Components')]);
        document.getElementById('footer-text').textContent = t('nui_footer_customize', 'Adjust components and coat, then Save');

        const baseCoat = data.coat || { tint0: 0, tint1: 255, tint2: 255 };
        // Backwards compat: old saves lack mane/tail, default them to main coat
        if (baseCoat.mane === undefined || baseCoat.mane === null) baseCoat.mane = baseCoat.tint0 || 0;
        if (baseCoat.tail === undefined || baseCoat.tail === null) baseCoat.tail = baseCoat.tint0 || 0;
        this.customizeData = {
            horseId: data.horseId,
            categories: data.categories || [],
            components: data.components || {},
            initialComponents: JSON.parse(JSON.stringify(data.components || {})),
            coat: baseCoat,
            initialCoat: JSON.parse(JSON.stringify(baseCoat)),
            hasMarkings: data.hasMarkings !== false,
            originalMarking: data.originalMarking,
            maneTailSupported: data.maneTailSupported !== false,
            prices: data.prices || { component: 10, coat: 5 },
            currentPrice: 0
        };

        this.renderComponents();
        this.renderCoatSwatches();
        this.applyMarkingsHint();
        this.updateCustomizePrice();

        this.showScreen('customize');
    },

    renderComponents() {
        const grid = document.getElementById('components-grid');
        grid.innerHTML = '';

        const categoryIcons = {
            Blankets: 'icons/horse_blankets.png',
            Saddles: 'icons/horse_saddles.png',
            Horns: 'icons/saddle_horns.png',
            Saddlebags: 'icons/horse_saddlebags.png',
            Stirrups: 'icons/saddle_stirrups.png',
            Bedrolls: 'icons/horse_bedrolls.png',
            Tails: 'icons/horse_tails.png',
            Manes: 'icons/horse_manes.png',
        };

        if (this.customizeData.categories) {
            this.customizeData.categories.forEach(cat => {
                const card = document.createElement('div');
                card.className = 'component-category-card';
                const currentValue = this.customizeData.components[cat.category] || 0;
                const maxValue = cat.items.length;

                card.innerHTML = `
                    <div class="component-category-header">
                        <div class="component-category-icon"><img src="${cat.icon}" alt=""></div>
                        <div class="component-category-info">
                            <div class="component-category-name">${cat.category.toUpperCase()}</div>
                            <div class="component-category-value">${t('nui_option_count_format', 'Option %s / %s').replace('%s', currentValue).replace('%s', maxValue)}</div>
                        </div>
                    </div>
                    <div class="coat-stepper" data-category="${cat.category}" data-min="0" data-max="${maxValue}">
                        <button class="coat-arrow component-dec" title="${t('nui_previous', 'Previous')}"><img src="icons/selection_arrow_left.png" alt="&lt;"></button>
                        <span class="component-category-value-inline">${currentValue} / ${maxValue}</span>
                        <button class="coat-arrow component-inc" title="${t('nui_next', 'Next')}"><img src="icons/selection_arrow_right.png" alt="&gt;"></button>
                    </div>
                `;

                const setComponent = (value) => {
                    value = Math.max(0, Math.min(maxValue, value));
                    this.customizeData.components[cat.category] = value;
                    card.querySelector('.component-category-value').textContent = t('nui_option_count_format', 'Option %s / %s').replace('%s', value).replace('%s', maxValue);
                    const inline = card.querySelector('.component-category-value-inline');
                    if (inline) inline.textContent = `${value} / ${maxValue}`;
                    this.updateCustomizePrice();
                    this.sendNUI('customizeComponent', { category: cat.category, value });
                };
                const dec = card.querySelector('.component-dec');
                const inc = card.querySelector('.component-inc');
                this.bindHold(dec, () => setComponent((this.customizeData.components[cat.category] || 0) - 1));
                this.bindHold(inc, () => setComponent((this.customizeData.components[cat.category] || 0) + 1));

                grid.appendChild(card);
            });
        }
    },

    applyMarkingsHint() {
        const hint = document.getElementById('coat-markings-hint');
        if (!hint) return;
        if (this.customizeData.hasMarkings === false) {
            hint.textContent = t('nui_markings_hint_none', 'This horse has no markings by default (255). Lower the value to try adding white markings — some breeds show no change.');
            hint.style.opacity = '1';
        } else {
            hint.textContent = t('nui_markings_hint_has', 'This horse has markings — adjust to change face/leg white. Set 255 for no markings.');
        }
    },

    sendCoatUpdate() {
        this.updateCustomizePrice();
        this.sendNUI('customizeCoat', {
            tint0: this.customizeData.coat.tint0,
            tint1: this.customizeData.coat.tint1,
            tint2: this.customizeData.coat.tint2,
            mane: this.customizeData.coat.mane,
            tail: this.customizeData.coat.tail
        });
    },

    renderCoatSwatches() {
        const coat = this.customizeData.coat;
        this.renderSwatchGrid('coat-tint0-grid', coat.tint0 || 0, 0, 254, 'tint0', true);
        this.renderSwatchGrid('coat-tint1-grid', (coat.tint1 === undefined || coat.tint1 === null) ? 255 : coat.tint1, 0, 255, 'tint1', false);
        this.renderSwatchGrid('coat-tint2-grid', (coat.tint2 === undefined || coat.tint2 === null) ? 255 : coat.tint2, 0, 255, 'tint2', false);
        this.renderSwatchGrid('coat-mane-grid', (coat.mane === undefined || coat.mane === null) ? (coat.tint0 || 0) : coat.mane, 0, 254, 'mane', false);
        this.renderSwatchGrid('coat-tail-grid', (coat.tail === undefined || coat.tail === null) ? (coat.tint0 || 0) : coat.tail, 0, 254, 'tail', false);
        this.setupCoatSliders();
    },

    setCoatTint(tintKey, value) {
        const stepper = document.querySelector(`.coat-stepper[data-tint="${tintKey}"]`);
        const min = stepper ? parseInt(stepper.dataset.min || '0') : 0;
        const max = stepper ? parseInt(stepper.dataset.max || '254') : 254;
        value = Math.max(min, Math.min(max, value));
        this.customizeData.coat[tintKey] = value;
        const valueDisplay = document.getElementById(`coat-${tintKey}-value`);
        if (valueDisplay) valueDisplay.textContent = value;
        const container = document.getElementById(`coat-${tintKey}-grid`);
        if (container) {
            container.querySelectorAll('.color-swatch').forEach(s => {
                s.classList.toggle('active', parseInt(s.dataset.value) === value);
            });
        }
        this.sendCoatUpdate();
    },

    // Shared press-and-hold repeater for arrow buttons.
    // click = exactly one step (most reliable event in NUI/CEF).
    // mousedown-hold = auto-repeat; mouseup/leave cancels. No pointer events:
    // they proved unreliable across repeated clicks in this CEF build.
    bindHold(btn, fn) {
        if (!btn) return;
        const fresh = btn.cloneNode(true);
        btn.replaceWith(fresh);
        let t = null, iv = null;
        const clear = () => { if (t) clearTimeout(t); if (iv) clearInterval(iv); t = iv = null; };
        fresh.addEventListener('click', () => {
            clear();
            fn();
        });
        fresh.addEventListener('mousedown', () => {
            clear();
            t = setTimeout(() => { iv = setInterval(fn, 60); }, 450);
        });
        ['mouseup', 'mouseleave'].forEach(ev => fresh.addEventListener(ev, clear));
        return fresh;
    },

    setupCoatSliders() {
        // Arrow steppers (click = +-1, hold = repeat). Replaces the old sliders.
        ['tint0', 'tint1', 'tint2', 'mane', 'tail'].forEach(tintKey => {
            const dec = document.getElementById(`coat-${tintKey}-dec`);
            const inc = document.getElementById(`coat-${tintKey}-inc`);
            const valueDisplay = document.getElementById(`coat-${tintKey}-value`);
            if (!dec || !inc || !valueDisplay) return;
            const fallback = (tintKey === 'tint1' || tintKey === 'tint2') ? 255 : (this.customizeData.coat.tint0 || 0);
            const current = (this.customizeData.coat[tintKey] === undefined || this.customizeData.coat[tintKey] === null) ? fallback : this.customizeData.coat[tintKey];
            this.customizeData.coat[tintKey] = current;
            valueDisplay.textContent = current;

            const step = (dir) => {
                const cur = this.customizeData.coat[tintKey] || 0;
                this.setCoatTint(tintKey, cur + dir);
            };
            this.bindHold(dec, () => step(-1));
            this.bindHold(inc, () => step(1));
        });
    },

    renderSwatchGrid(containerId, currentValue, min, max, tintKey, includePresets) {
        const container = document.getElementById(containerId);
        container.innerHTML = '';

        // Coat presets from Config.CoatPresets (tint0 only)
        const coatPresets = [
            { name: t('nui_color_white', 'White'), tint0: 0 },
            { name: t('nui_color_black', 'Black'), tint0: 9 },
            { name: t('nui_color_brown', 'Brown'), tint0: 40 },
            { name: t('nui_color_bay', 'Bay'), tint0: 100 },
            { name: t('nui_color_purple', 'Purple'), tint0: 105 },
            { name: t('nui_color_pink', 'Pink'), tint0: 107 },
            { name: t('nui_color_lilac', 'Lilac'), tint0: 108 },
            { name: t('nui_color_dark_green', 'Dark Green'), tint0: 109 },
            { name: t('nui_color_blue', 'Blue'), tint0: 110 },
            { name: t('nui_color_green', 'Green'), tint0: 112 },
            { name: t('nui_color_lime', 'Lime'), tint0: 115 },
            { name: t('nui_color_yellow', 'Yellow'), tint0: 119 },
            { name: t('nui_color_orange', 'Orange'), tint0: 120 },
            { name: t('nui_color_bronze', 'Bronze'), tint0: 121 },
            { name: t('nui_color_blood_red', 'Blood Red'), tint0: 125 },
            { name: t('nui_color_chestnut_red', 'Chestnut Red'), tint0: 127 },
            { name: t('nui_color_silver', 'Silver'), tint0: 128 },
            { name: t('nui_color_grey', 'Grey'), tint0: 130 },
        ];

        // Show presets first for tint0, then regular swatches
        if (includePresets && tintKey === 'tint0') {
            const presetRow = document.createElement('div');
            presetRow.className = 'coat-preset-row';
            presetRow.innerHTML = `<span class="coat-preset-label">${t('nui_presets', 'PRESETS')}</span>`;
            container.appendChild(presetRow);

            const presetGrid = document.createElement('div');
            presetGrid.className = 'color-swatch-grid preset-grid';
            coatPresets.forEach(preset => {
                const swatch = document.createElement('button');
                swatch.className = 'color-swatch preset-swatch' + (preset.tint0 === currentValue ? ' active' : '');
                swatch.dataset.value = preset.tint0;
                swatch.dataset.tint = tintKey;
                swatch.style.background = this.getCoatColor(tintKey, preset.tint0);
                swatch.title = preset.name;
                swatch.addEventListener('click', () => {
                    this.setCoatTint(tintKey, preset.tint0);
                });
                presetGrid.appendChild(swatch);
            });
            container.appendChild(presetGrid);

            // Add separator
            const separator = document.createElement('div');
            separator.className = 'coat-preset-separator';
            separator.innerHTML = `<span>${t('nui_custom', 'CUSTOM')}</span>`;
            container.appendChild(separator);
        }

        // Show a subset of values (every 16th for performance, plus current)
        const step = 16;
        const values = new Set();
        for (let i = min; i <= max; i += step) values.add(i);
        values.add(currentValue);
        const sortedValues = Array.from(values).sort((a, b) => a - b);

        const customGrid = document.createElement('div');
        customGrid.className = 'color-swatch-grid';
        sortedValues.forEach(val => {
            const swatch = document.createElement('button');
            swatch.className = 'color-swatch' + (val === currentValue ? ' active' : '');
            swatch.dataset.value = val;
            swatch.dataset.tint = tintKey;
            swatch.style.background = this.getCoatColor(tintKey, val);
            swatch.title = `${tintKey}: ${val}`;
            swatch.addEventListener('click', () => {
                // Tapping "255" on markings = explicit "no markings" preset
                this.setCoatTint(tintKey, val);
            });
            customGrid.appendChild(swatch);
        });
        container.appendChild(customGrid);
    },

    getCoatColor(tintKey, value) {
        // Generate approximate colors for horse coat tints
        // These are approximations - real colors come from game assets
        if (tintKey === 'tint0' || tintKey === 'mane' || tintKey === 'tail') {
            // Main coat / mane / tail colors (0-254)
            const hue = (value / 254) * 60; // 0-60 (browns)
            return `hsl(${hue}, 40%, ${20 + (value / 254) * 30}%)`;
        } else if (tintKey === 'tint1') {
            // Markings (0-255) - whites/greys
            if (value === 255) return '#1a1a1a'; // "none" - dark
            const lightness = (value / 255) * 80 + 10;
            return `hsl(0, 0%, ${lightness}%)`;
        } else {
            // Nose (0-255) - pinks/browns
            if (value === 255) return '#1a1a1a'; // "none"
            const hue = 15 + (value / 255) * 20; // pink to brown
            return `hsl(${hue}, 50%, ${30 + (value / 255) * 30}%)`;
        }
    },

    updateCustomizePrice() {
        const { components, initialComponents, coat, initialCoat, prices } = this.customizeData;
        let price = 0;

        // Component price: count changed components
        for (const [cat, value] of Object.entries(components)) {
            if (value !== (initialComponents[cat] || 0) && value > 0) {
                price += prices.component || 10;
            }
        }

        // Coat price: any tint changed (coat, markings, nose, mane, tail)
        const norm = (v, fb) => (v === undefined || v === null) ? fb : v;
        const coatChanged = norm(coat.tint0, 0) !== norm(initialCoat.tint0, 0) ||
                           norm(coat.tint1, 255) !== norm(initialCoat.tint1, 255) ||
                           norm(coat.tint2, 255) !== norm(initialCoat.tint2, 255) ||
                           norm(coat.mane, norm(coat.tint0, 0)) !== norm(initialCoat.mane, norm(initialCoat.tint0, 0)) ||
                           norm(coat.tail, norm(coat.tint0, 0)) !== norm(initialCoat.tail, norm(initialCoat.tint0, 0));
        if (coatChanged) {
            price += prices.coat || 5;
        }

        this.customizeData.currentPrice = price;
        document.getElementById('customize-price').textContent = '$' + price.toFixed(2);
    },

    setupCustomizationEvents() {
        document.getElementById('customize-cancel').addEventListener('click', () => this.cancelCustomization());
        document.getElementById('customize-save').addEventListener('click', () => this.saveCustomization());
    },

    cancelCustomization() {
        // Restore initial state
        this.sendNUI('cancelCustomization', { 
            components: this.customizeData.initialComponents,
            coat: this.customizeData.initialCoat
        });
        this.goBack();
    },

    saveCustomization() {
        this.sendNUI('saveCustomization', {
            horseId: this.customizeData.horseId,
            components: this.customizeData.components,
            coat: this.customizeData.coat,
            price: this.customizeData.currentPrice
        });
        this.showSuccess(t('nui_customization_saved', 'Customization saved!'), false);
        this.goBack();
    },

    renderCurrentScreen() {
        // Re-render the current screen based on search/sort (used for shop)
        // This is a no-op for non-shop screens since they don't re-render
    }
};

// Wild horse sell/save panel + appraisal progress (merged from rsg-wildhorse).
// Fully namespaced (wh-) so it never touches the stable UI above.
const WildHorseUI = {
    progressTimer: null,
    progressStart: 0,
    progressDuration: 0,
    stages: [
        [0, () => t('nui_stage_inspecting', 'INSPECTING THE HORSE')],
        [22, () => t('nui_stage_checking', 'CHECKING BREED AND MARKINGS')],
        [47, () => t('nui_stage_assessing', 'ASSESSING CONDITION')],
        [70, () => t('nui_stage_confirming', 'CONFIRMING OWNERSHIP')],
        [88, () => t('nui_stage_preparing', 'PREPARING THE SALE')],
        [97, () => t('nui_stage_finalising', 'FINALISING APPRAISAL')]
    ],

    post(name) {
        return fetch(`https://rsg-horses/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: '{}'
        }).catch(() => {});
    },

    open(title) {
        const root = document.getElementById('wh-root');
        if (!root) return;
        document.getElementById('wh-title').textContent = title || t('nui_wild_horse_title', 'WILD HORSE');
        root.classList.remove('hidden');
    },

    hide() {
        const root = document.getElementById('wh-root');
        if (root) root.classList.add('hidden');
    },

    closeMenu() {
        const root = document.getElementById('wh-root');
        const visible = root && !root.classList.contains('hidden');
        if (root) root.classList.add('hidden');
        if (visible) this.post('whClose');
    },

    setStage(index) {
        document.querySelectorAll('#wh-progressRoot .wh-stage').forEach((el, i) => {
            el.classList.toggle('active', i === index);
            el.classList.toggle('complete', i < index);
        });
    },

    setFillState(pct) {
        const fill = document.getElementById('wh-progressFill');
        if (!fill) return;
        fill.classList.remove('wh-stat-good', 'wh-stat-warn', 'wh-stat-bad');
        if (pct >= 88) fill.classList.add('wh-stat-good');
        else if (pct >= 60) fill.classList.add('wh-stat-warn');
        else fill.classList.add('wh-stat-good');
    },

    startProgress(duration) {
        clearInterval(this.progressTimer);
        this.progressDuration = Math.max(250, Number(duration) || 5000);
        this.progressStart = performance.now();

        const root = document.getElementById('wh-progressRoot');
        const fill = document.getElementById('wh-progressFill');
        if (!root || !fill) return;

        fill.style.width = '0%';
        document.getElementById('wh-progressPercent').textContent = '0%';
        document.getElementById('wh-progressStage').textContent = this.stages[0][1]();
        document.getElementById('wh-progressTime').textContent = `${(this.progressDuration / 1000).toFixed(1)}s`;
        document.getElementById('wh-progressHint').textContent = t('nui_please_wait', 'PLEASE WAIT');
        this.setStage(0);
        this.setFillState(0);

        root.classList.remove('hidden');
        root.setAttribute('aria-hidden', 'false');

        this.progressTimer = setInterval(() => {
            const elapsed = performance.now() - this.progressStart;
            const pct = Math.min(100, (elapsed / this.progressDuration) * 100);
            const remaining = Math.max(0, this.progressDuration - elapsed);

            fill.style.width = `${pct.toFixed(1)}%`;
            document.getElementById('wh-progressPercent').textContent = `${Math.floor(pct)}%`;
            document.getElementById('wh-progressTime').textContent = `${(remaining / 1000).toFixed(1)}s`;

            let currentIndex = 0;
            for (let i = 0; i < this.stages.length; i++) {
                if (pct >= this.stages[i][0]) currentIndex = i;
            }

            document.getElementById('wh-progressStage').textContent = this.stages[currentIndex][1]();
            this.setStage(currentIndex);
            this.setFillState(pct);

            if (pct >= 100) {
                clearInterval(this.progressTimer);
                this.progressTimer = null;
                document.getElementById('wh-progressStage').textContent = t('nui_appraisal_complete', 'APPRAISAL COMPLETE');
                document.getElementById('wh-progressPercent').textContent = '100%';
                document.getElementById('wh-progressTime').textContent = '0.0s';
                document.getElementById('wh-progressHint').textContent = t('nui_completing_sale', 'COMPLETING SALE');
                this.setStage(5);
            }
        }, 50);
    },

    stopProgress() {
        clearInterval(this.progressTimer);
        this.progressTimer = null;
        const root = document.getElementById('wh-progressRoot');
        const fill = document.getElementById('wh-progressFill');
        if (root) {
            root.classList.add('hidden');
            root.setAttribute('aria-hidden', 'true');
        }
        if (fill) fill.style.width = '0%';
        this.setStage(0);
    },

    init() {
        const close = () => this.closeMenu();
        const closeBtn = document.getElementById('wh-closeBtn');
        const backBtn = document.getElementById('wh-backBtn');
        const sellBtn = document.getElementById('wh-sellBtn');
        const saveBtn = document.getElementById('wh-saveBtn');
        if (closeBtn) closeBtn.onclick = close;
        if (backBtn) backBtn.onclick = close;
        if (sellBtn) sellBtn.onclick = () => {
            this.hide();
            this.post('whSell');
        };
        if (saveBtn) saveBtn.onclick = () => {
            this.hide();
            this.post('whSave');
        };
        document.addEventListener('keydown', (event) => {
            if (event.key === 'Escape') {
                const root = document.getElementById('wh-root');
                if (root && !root.classList.contains('hidden')) close();
            }
        });
    }
};

document.addEventListener('DOMContentLoaded', () => {
    HorseUI.init();
    WildHorseUI.init();
});

const style = document.createElement('style');
style.textContent = `
    @keyframes notifyOut {
        from { transform: translateX(0); opacity: 1; }
        to { transform: translateX(30px); opacity: 0; }
    }
    .btn-purchase.purchasing { pointer-events: none; opacity: 0.7; }
`;
document.head.appendChild(style);
