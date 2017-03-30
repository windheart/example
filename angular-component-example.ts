
import { Component, OnInit, Input, OnDestroy } from '@angular/core';
import { NgForm } from "@angular/forms";

import { PaymentFlow } from "../../interfaces/payment-flow.model";
import { PaymentFlowService } from "../../services/payment-flow.service";
import { AppService } from "../../services/app.service";
import { Subscription } from 'rxjs/Subscription';


@Component({
    selector: 'cart',
    templateUrl: 'cart.component.html',
    styleUrls: ['cart.component.scss'],
})

export class CartComponent implements OnInit, OnDestroy {
    loading: boolean;

    private name: string = 'cart';
    private cartPristineData: any;
    private subscriptions: Subscription[] = [];

    @Input() hasToolbar: boolean = true;
    @Input() viewMode: string = 'preview';
    @Input() flow: PaymentFlow;

    constructor(
        private appService: AppService,
        private flowService: PaymentFlowService) {}

    ngOnInit(): void {
        this.keepPristineData();
        this.subscribeOnChanges();
    }

    ngOnDestroy(): void {
        this.unsubscribeFromChanges();
    }

    cancel(event: Event, form: NgForm): void {
        event.preventDefault();
        if (form.dirty) {
            this.restorePristineData();
        }
        this.preview();
    }

    save(event: Event, form: NgForm): void {
        event.preventDefault();
        if (form.dirty) {
            this.loading = true;
            this.flowService
                .save('cart', 'payment_option_id')
                .subscribe(() => {
                    this.loading = false;
                    this.appService.cartChanges.emit();
                    this.keepPristineData();
                    this.preview()
                });
        } else {
            this.preview();
        }
    }

    toggleViewMode(event: Event) {
        event.preventDefault();
        this.viewMode == 'preview' ? this.edit() : this.preview();
    }

    keepPristineData() {
        if (this.flow.cart) {
            this.cartPristineData = JSON.parse(JSON.stringify(this.flow.cart));
        }
    }

    restorePristineData() {
        if (this.cartPristineData) {
            this.flow.cart = JSON.parse(JSON.stringify(this.cartPristineData));
        }
    }

    ensureViewMode(componentName: string) {
        if (this.name != componentName && this.viewMode == 'edit') {
            this.restorePristineData();
            this.preview();
        }
    }

    edit(): void {
        this.viewMode = 'edit';
        this.appService.viewModeChanges.emit(this.name);
    }

    preview(): void {
        this.viewMode = 'preview';
    }

    get minimized(): boolean {
        return this.viewMode == 'preview';
    }

    private subscribeOnChanges() {
        this.subscriptions.push(
            this.appService.viewModeChanges.subscribe((componentName: string) => this.ensureViewMode(componentName))
        );
    }

    private unsubscribeFromChanges() {
        this.subscriptions.forEach(subscription => subscription.unsubscribe());
    }
}
